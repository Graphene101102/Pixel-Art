import UIKit

struct LevelData: Identifiable {
    let id = UUID()
    var name: String
    
    let gridWidth: Int
    let gridHeight: Int
    
    var pixels: [PixelData]
    
    var paletteModels: [ColorModel]
    
    var palette: [UIColor] {
        return paletteModels.map { $0.toUIColor }
    }
    
    var maxDimension: Int {
        max(gridWidth, gridHeight)
    }
}

extension LevelData: Equatable {
    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        // So sánh các thuộc tính quan trọng để biết level có thay đổi không
        return lhs.gridWidth == rhs.gridWidth &&
               lhs.gridHeight == rhs.gridHeight &&
               lhs.pixels == rhs.pixels // Quan trọng: So sánh mảng pixel
    }
}
