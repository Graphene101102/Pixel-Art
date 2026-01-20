import UIKit
import Combine

class GameViewModel {
    
    // MARK: - Publishers (Đã tối ưu luồng)
    
    // 1. Dùng PassthroughSubject thay vì CurrentValueSubject để tránh tự động bắn tin khi không cần thiết
    // Chỉ dùng khi cần vẽ lại TOÀN BỘ (Lúc mới vào game, lúc Reset Zoom)
    let levelSubject = PassthroughSubject<LevelData, Never>()
    
    // 2. Dùng để báo hiệu cập nhật từng ô (Tối ưu hiệu năng tô màu)
    let changesSubject = PassthroughSubject<[Int], Never>()
    
    // 3. Các sự kiện khác giữ nguyên
    let selectedColorIndex = CurrentValueSubject<Int, Never>(0)
    let isComplete = PassthroughSubject<Void, Never>()
    let isMusicOn = CurrentValueSubject<Bool, Never>(true)
    let isMagicWandMode = CurrentValueSubject<Bool, Never>(false)
    let resetZoomRequest = PassthroughSubject<Void, Never>()
    
    // MARK: - Data Storage (Lưu trữ dữ liệu thực tế)
    // Thay vì dựa vào Subject để giữ dữ liệu, ta dùng biến riêng
    private(set) var currentLevelData: LevelData
    
    var currentNumber: Int { selectedColorIndex.value + 1 }
    
    // Biến đếm tối ưu check win (O(1) thay vì duyệt mảng)
    private var coloredPixelsCount: Int = 0
    private var totalColorablePixels: Int = 0
    
    private var saveTimer: Timer?
    private var gameplayTimer: Timer?
    
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
        self.currentLevelData = level
        self.calculateProgressInfo()
    }
    
    // Tính toán trước số lượng pixel để check win nhanh
    private func calculateProgressInfo() {
        let pixels = currentLevelData.pixels
        self.totalColorablePixels = pixels.filter { $0.number > 0 }.count
        self.coloredPixelsCount = pixels.filter { $0.number > 0 && $0.isColored }.count
    }
    
    // [QUAN TRỌNG] Hàm này được gọi từ VC khi viewDidAppear để vẽ lần đầu
    func loadInitialLevel() {
        levelSubject.send(currentLevelData)
    }
    
    // MARK: - Timer Logic
    func startGameplayTimer() {
        gameplayTimer?.invalidate()
        gameplayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentLevelData.timeSpent += 1
            // Không bắn levelSubject ở đây để tránh vẽ lại UI
        }
    }
    
    func stopGameplayTimer() {
        gameplayTimer?.invalidate()
        gameplayTimer = nil
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
        guard index >= 0 && index < currentLevelData.pixels.count else { return }
        let pixel = currentLevelData.pixels[index]
        
        if !pixel.isColored && pixel.number == currentNumber {
            attemptToColor(indices: [index])
        } else if !pixel.isColored && pixel.number > 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func attemptToColor(indices: [Int]) {
        var changedIndices: [Int] = []
        var didColor = false
        
        // Thao tác trực tiếp trên biến currentLevelData
        for index in indices {
            if index < currentLevelData.pixels.count {
                if !currentLevelData.pixels[index].isColored && currentLevelData.pixels[index].number == currentNumber {
                    
                    // Cập nhật trạng thái
                    currentLevelData.pixels[index].isColored = true
                    coloredPixelsCount += 1 // Tăng biến đếm
                    
                    changedIndices.append(index)
                    didColor = true
                }
            }
        }
        
        if didColor {
            // [CỰC KỲ QUAN TRỌNG]
            // Chỉ gửi danh sách index thay đổi.
            // KHÔNG gửi levelSubject.send() để tránh vẽ lại toàn bộ.
            changesSubject.send(changedIndices)
            
            // Logic check win tối ưu
            if coloredPixelsCount >= totalColorablePixels {
                handleWin()
            } else {
                scheduleAutoSave()
            }
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    func triggerSmartMagic() {
        var changedIndices: [Int] = []
        let currentNum = currentNumber
        var targetNumber = currentNum
        
        let hasUncoloredCurrent = currentLevelData.pixels.contains { $0.number == currentNum && !$0.isColored }
        if !hasUncoloredCurrent {
            let incompleteNumbers = (1...currentLevelData.paletteModels.count).filter { num in
                currentLevelData.pixels.contains(where: { $0.number == num && !$0.isColored })
            }
            if let randomNum = incompleteNumbers.randomElement() {
                targetNumber = randomNum
                selectedColorIndex.send(targetNumber - 1)
            } else { return }
        }
        
        for i in 0..<currentLevelData.pixels.count {
            if currentLevelData.pixels[i].number == targetNumber && !currentLevelData.pixels[i].isColored {
                currentLevelData.pixels[i].isColored = true
                coloredPixelsCount += 1
                changedIndices.append(i)
            }
        }
        
        if !changedIndices.isEmpty {
            changesSubject.send(changedIndices)
            if coloredPixelsCount >= totalColorablePixels { handleWin() }
            else { scheduleAutoSave() }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // MARK: - Helpers & Save
    
    private func handleWin() {
        stopGameplayTimer()
        saveProgress()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isComplete.send()
        }
    }
    
    func toggleMusic() {
        SoundManager.shared.toggleMute()
        isMusicOn.send(!SoundManager.shared.isMuted)
    }
    
    func triggerFitToScreen() { resetZoomRequest.send() }
    
    func triggerCheckButton() { isComplete.send() }
    
    func findUncoloredPixelIndex() -> Int? {
        let currentNum = currentNumber
        return currentLevelData.pixels.firstIndex(where: { $0.number == currentNum && !$0.isColored })
    }
    
    func canStartPainting(at index: Int) -> Bool {
        if index < 0 || index >= currentLevelData.pixels.count { return false }
        let pixel = currentLevelData.pixels[index]
        return !pixel.isColored && pixel.number == currentNumber
    }

    private func scheduleAutoSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.saveProgress()
        }
    }
    
    func saveProgress() {
        print("💾 Saving Progress...")
        var dataToSave = currentLevelData
        dataToSave.createdAt = Date()
        GameStorageManager.shared.saveLevelProgress(dataToSave)
        NotificationCenter.default.post(name: NSNotification.Name("DidUpdateLevelProgress"), object: nil)
    }
}
