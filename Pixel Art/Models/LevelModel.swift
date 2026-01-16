import UIKit
import FirebaseFirestore

struct LevelModel: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String

    var gridWidth: Int
    var gridHeight: Int
    
    var palette: [ColorModel] // Lưu mảng màu thô
    var pixelsNumber: [Int]
    var author: String?
    var createdAt: Date
    
    // --- CHIỀU ĐI: App (LevelData) -> Firebase (LevelModel) ---
    init(from levelData: LevelData) {
        self.name = levelData.name
        self.gridWidth = levelData.gridWidth
        self.gridHeight = levelData.gridHeight
        self.createdAt = Date()
        self.author = "User"
        self.palette = levelData.paletteModels
        self.pixelsNumber = levelData.pixels.map { $0.number }
    }
}

// --- CHIỀU VỀ: Firebase (LevelModel) -> App (LevelData) ---
extension LevelData {
    init(from model: LevelModel) {
        self.name = model.name
        self.gridWidth = model.gridWidth
        self.gridHeight = model.gridHeight
        
        self.paletteModels = model.palette
        
        // Tái tạo lại các ô pixel từ mảng số
        var loadedPixels: [PixelData] = []
        
        for y in 0..<model.gridHeight {
            for x in 0..<model.gridWidth {
                // Tính index trong mảng 1 chiều
                let index = y * model.gridWidth + x
                
                if index < model.pixelsNumber.count {
                    let number = model.pixelsNumber[index]
                    
                    // Trường hợp số 0 (Nền trong suốt/trắng)
                    if number == 0 {
                        loadedPixels.append(PixelData(
                            x: x,
                            y: y,
                            number: 0,
                            rawColor: ColorModel(r: 1, g: 1, b: 1), // Màu trắng mặc định
                            isColored: true, // Coi như đã tô
                        ))
                        continue
                    }
                    
                    // Trường hợp có màu (số >= 1)
                    let colorIndex = number - 1
                    
                    // Tìm màu trong palette (kiểm tra an toàn để không crash)
                    let rawColor = (colorIndex >= 0 && colorIndex < self.paletteModels.count)
                        ? self.paletteModels[colorIndex]
                        : ColorModel(r: 0, g: 0, b: 0) // Fallback màu đen nếu lỗi
                    
                    loadedPixels.append(PixelData(
                        x: x,
                        y: y,
                        number: number,
                        rawColor: rawColor,
                        isColored: false, // Mới tải về thì chưa tô
                    ))
                }
            }
        }
        self.pixels = loadedPixels
    }
}
