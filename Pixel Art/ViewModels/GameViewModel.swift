import UIKit
import Combine

class GameViewModel {
    
    // MARK: - OUTPUT (Dữ liệu gửi ra View)
    let levelSubject: CurrentValueSubject<LevelData, Never>
    let selectedColorIndex = CurrentValueSubject<Int, Never>(0)
    let isComplete = PassthroughSubject<Void, Never>()
    let isMusicOn = CurrentValueSubject<Bool, Never>(true)
    let isMagicWandMode = CurrentValueSubject<Bool, Never>(false)
    
    // Báo cho View biết cần vẽ lại những pixel nào
    let changesSubject = PassthroughSubject<[Int], Never>()
    
    // MARK: - INTERNAL STATE
    var currentNumber: Int { selectedColorIndex.value + 1 }
    
    // MARK: - INIT
    init(level: LevelData) {
        self.levelSubject = CurrentValueSubject(level)
    }
    
    // MARK: - LOGIC TÔ MÀU (INPUT MỚI)
    // Hàm này nhận trực tiếp Index từ CanvasView (đã được tính toán chuẩn xác)
    func handleTap(atIndex index: Int) {
        var currentLvl = levelSubject.value
        
        // 1. Kiểm tra index hợp lệ
        guard index >= 0 && index < currentLvl.pixels.count else { return }
        
        let pixel = currentLvl.pixels[index]
        
        // 2. Kiểm tra logic tô màu
        if !pixel.isColored && pixel.number == currentNumber {
            attemptToColor(index: index)
        } else {
            // Rung báo lỗi nếu chọn sai
            if !pixel.isColored && pixel.number > 0 {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
    
    // Hàm thực hiện tô màu và báo về View
    func attemptToColor(index: Int) {
        attemptToColor(indices: [index])
    }
    
    func attemptToColor(indices: [Int]) {
        var lvl = levelSubject.value
        var changedIndices: [Int] = []
        var didColor = false
        
        for index in indices {
            // Kiểm tra hợp lệ cho từng ô
            if index >= 0 && index < lvl.pixels.count {
                let pixel = lvl.pixels[index]
                
                // Logic: Chưa tô + Đúng màu
                if !pixel.isColored && pixel.number == currentNumber {
                    lvl.pixels[index].isColored = true
                    changedIndices.append(index)
                    didColor = true
                }
            }
        }
        
        // Chỉ cập nhật nếu có ít nhất 1 ô thay đổi
        if didColor {
            // 1. Cập nhật Data
            levelSubject.send(lvl)
            
            // 2. Báo View vẽ lại (Gửi cả danh sách để View vẽ 1 thể)
            changesSubject.send(changedIndices)
            
            // 3. Rung nhẹ (Chỉ rung 1 lần cho cả cụm để đỡ lag máy)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // 4. Kiểm tra thắng
            checkWin(lvl: lvl)
        }
    }
    
    // MARK: - Nhạc nền
    
    func toggleMusic() {
        SoundManager.shared.toggleMute()
        isMusicOn.send(!SoundManager.shared.isMuted)
    }
    
    // MARK: - Kiểm tra pan là tô hay di chuyển
    func canStartPainting(at index: Int) -> Bool {
            let lvl = levelSubject.value
            
            // 1. Kiểm tra index hợp lệ
            if index < 0 || index >= lvl.pixels.count { return false }
            
            let pixel = lvl.pixels[index]
            
            // 2. Chỉ cho phép tô nếu:
            // - Ô đó chưa được tô màu
            // - VÀ Số của ô đó trùng với số màu đang chọn
            if !pixel.isColored && pixel.number == currentNumber {
                return true
            }
            
            return false
        }
    
    // MARK: - Tô tất cả ô
    func triggerSmartMagic() {
        var currentLvl = levelSubject.value
        var changedIndices: [Int] = []
        let currentNum = currentNumber
        
        // Logic tìm số cần tô
        let hasUncoloredCurrent = currentLvl.pixels.contains { $0.number == currentNum && !$0.isColored }
        var targetNumber = currentNum
        
        if !hasUncoloredCurrent {
            let allNumbers = 1...currentLvl.palette.count
            let incompleteNumbers = allNumbers.filter { num in
                currentLvl.pixels.contains(where: { $0.number == num && !$0.isColored })
            }
            
            if let randomNum = incompleteNumbers.randomElement() {
                targetNumber = randomNum
                selectedColorIndex.send(targetNumber - 1)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
        }
        
        // Tô tất cả ô của số đó
        for i in 0..<currentLvl.pixels.count {
            if currentLvl.pixels[i].number == targetNumber && !currentLvl.pixels[i].isColored {
                currentLvl.pixels[i].isColored = true
                changedIndices.append(i)
            }
        }
        
        if !changedIndices.isEmpty {
            levelSubject.send(currentLvl)
            changesSubject.send(changedIndices)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            checkWin(lvl: currentLvl)
        }
    }
    
    // MARK: - Kiểm tra hoàn thành
    private func checkWin(lvl: LevelData) {
        let required = lvl.pixels.filter { $0.number > 0 }
        if required.allSatisfy({ $0.isColored }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isComplete.send()
            }
        }
    }
    
    // MARK: - Tìm kiếm
    func findUncoloredPixelIndex() -> Int? {
        let currentLvl = levelSubject.value
        let currentNum = currentNumber
        if let index = currentLvl.pixels.firstIndex(where: { $0.number == currentNum && !$0.isColored }) {
            return index
        }
        return nil
    }
}
