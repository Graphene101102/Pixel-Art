import UIKit
import Combine

class GameViewModel {
    
    // MARK: - Properties
    let levelSubject: CurrentValueSubject<LevelData, Never>
    let selectedColorIndex = CurrentValueSubject<Int, Never>(0)
    let isComplete = PassthroughSubject<Void, Never>()
    let isMusicOn = CurrentValueSubject<Bool, Never>(true)
    let isMagicWandMode = CurrentValueSubject<Bool, Never>(false)
    let resetZoomRequest = PassthroughSubject<Void, Never>()
    let changesSubject = PassthroughSubject<[Int], Never>()
    
    var currentNumber: Int { selectedColorIndex.value + 1 }
    
    // [QUAN TRỌNG] Timer để hẹn giờ lưu file (tránh lưu liên tục gây lag)
    private var saveTimer: Timer?
    
    // MARK: - ITEM STORAGE (User Defaults)
    var magicWandCount: Int {
        get { UserDefaults.standard.object(forKey: "magicWandCount") as? Int ?? 3 }
        set { UserDefaults.standard.set(newValue, forKey: "magicWandCount") }
    }
    
    var searchItemCount: Int {
        get { UserDefaults.standard.object(forKey: "searchItemCount") as? Int ?? 3 }
        set { UserDefaults.standard.set(newValue, forKey: "searchItemCount") }
    }
    
    enum ItemType { case magicWand, search }
    
    // MARK: - Init
    init(level: LevelData) {
        self.levelSubject = CurrentValueSubject(level)
    }
    
    // MARK: - ITEM LOGIC
    func tryUseMagicWand() -> Bool {
        if magicWandCount > 0 {
            magicWandCount -= 1
            triggerSmartMagic()
            return true
        }
        return false
    }
    
    func tryUseSearch() -> Bool {
        if searchItemCount > 0 {
            if let _ = findUncoloredPixelIndex() {
                searchItemCount -= 1
                return true
            }
        }
        return false
    }
    
    func rewardItems(type: ItemType, amount: Int = 3) {
        switch type {
        case .magicWand: magicWandCount += amount
        case .search: searchItemCount += amount
        }
    }
    
    // MARK: - GAMEPLAY
    func handleTap(atIndex index: Int) {
        let currentLvl = levelSubject.value
        guard index >= 0 && index < currentLvl.pixels.count else { return }
        let pixel = currentLvl.pixels[index]
        
        if !pixel.isColored && pixel.number == currentNumber {
            attemptToColor(indices: [index])
        } else if !pixel.isColored && pixel.number > 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func attemptToColor(indices: [Int]) {
        var lvl = levelSubject.value
        var changedIndices: [Int] = []
        var didColor = false
        
        for index in indices {
            if index < lvl.pixels.count {
                let pixel = lvl.pixels[index]
                if !pixel.isColored && pixel.number == currentNumber {
                    lvl.pixels[index].isColored = true
                    changedIndices.append(index)
                    didColor = true
                }
            }
        }
        
        if didColor {
            // [TỐI ƯU] Chỉ gọi hàm cập nhật giao diện, KHÔNG lưu file ngay tại đây
            applyChanges(lvl: lvl, indices: changedIndices)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func triggerSmartMagic() {
        var currentLvl = levelSubject.value
        var changedIndices: [Int] = []
        let currentNum = currentNumber
        var targetNumber = currentNum
        
        // Logic chọn màu để dùng gậy thần
        let hasUncoloredCurrent = currentLvl.pixels.contains { $0.number == currentNum && !$0.isColored }
        if !hasUncoloredCurrent {
            let incompleteNumbers = (1...currentLvl.paletteModels.count).filter { num in
                currentLvl.pixels.contains(where: { $0.number == num && !$0.isColored })
            }
            if let randomNum = incompleteNumbers.randomElement() {
                targetNumber = randomNum
                selectedColorIndex.send(targetNumber - 1)
            } else { return }
        }
        
        // Tô màu
        for i in 0..<currentLvl.pixels.count {
            if currentLvl.pixels[i].number == targetNumber && !currentLvl.pixels[i].isColored {
                currentLvl.pixels[i].isColored = true
                changedIndices.append(i)
            }
        }
        
        if !changedIndices.isEmpty {
            applyChanges(lvl: currentLvl, indices: changedIndices)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // MARK: - Logic Cập nhật (RAM + Hẹn giờ lưu)
    private func applyChanges(lvl: LevelData, indices: [Int]) {
        // 1. Cập nhật dữ liệu trên RAM để vẽ lại màn hình ngay lập tức
        levelSubject.send(lvl)
        changesSubject.send(indices)
        
        // 2. Kiểm tra thắng
        checkWin(lvl: lvl)
        
        // 3. [TỐI ƯU] Gọi hàm hẹn giờ lưu. Nó sẽ không lưu ngay mà đợi bạn dừng tay.
        scheduleAutoSave()
    }
    
    // MARK: - Helpers
    func toggleMusic() {
        SoundManager.shared.toggleMute()
        isMusicOn.send(!SoundManager.shared.isMuted)
    }
    
    func triggerFitToScreen() { resetZoomRequest.send() }
    
    func triggerCheckButton() { isComplete.send() }
    
    private func checkWin(lvl: LevelData) {
        let required = lvl.pixels.filter { $0.number > 0 }
        if required.allSatisfy({ $0.isColored }) {
            // [QUAN TRỌNG] Khi thắng thì phải lưu NGAY LẬP TỨC để tránh mất dữ liệu khi hiện popup
            saveProgress()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.isComplete.send() }
        }
    }
    
    func findUncoloredPixelIndex() -> Int? {
        let currentLvl = levelSubject.value
        let currentNum = currentNumber
        return currentLvl.pixels.firstIndex(where: { $0.number == currentNum && !$0.isColored })
    }
    
    func canStartPainting(at index: Int) -> Bool {
        let lvl = levelSubject.value
        if index < 0 || index >= lvl.pixels.count { return false }
        let pixel = lvl.pixels[index]
        return !pixel.isColored && pixel.number == currentNumber
    }
    
    // MARK: - Logic Lưu Trữ Chống Lag
    private func scheduleAutoSave() {
        // Nếu timer cũ đang chạy (nghĩa là bạn vừa thao tác chưa đầy 3s), hủy nó đi
        saveTimer?.invalidate()
        
        // Đặt timer mới: "Sau 3 giây nữa, nếu không ai làm gì thì tôi sẽ lưu"
        saveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.saveProgress()
        }
    }
    
    // Hàm này mới thực sự ghi dữ liệu xuống ổ cứng
    func saveProgress() {
        print("💾 Đang lưu dữ liệu xuống máy...")
        // 1. Lấy dữ liệu hiện tại
        var currentData = levelSubject.value
        
        // 2. [MỚI] Cập nhật thời gian để đánh dấu là vừa mới chơi
        currentData.createdAt = Date()
        
        // 3. Lưu xuống ổ cứng
        GameStorageManager.shared.saveLevelProgress(currentData)
        
        // 4. [MỚI] Bắn thông báo để các màn hình bên ngoài (Home/Gallery) biết mà reload
        NotificationCenter.default.post(name: NSNotification.Name("DidUpdateLevelProgress"), object: nil)
    }
}
