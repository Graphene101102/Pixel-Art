import UIKit
import FirebaseFirestore

// Danh sách các danh mục mặc định (Fallback nếu chưa có trên Firebase)
enum Category: String, CaseIterable, Codable {
    case animals = "Động vật"
    case food = "Đồ ăn"
    case scenery = "Phong cảnh"
    case characters = "Nhân vật"
    case others = "Khác"
}

struct LevelData: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var category: String // [MỚI] Thêm trường category
    
    var gridWidth: Int
    var gridHeight: Int
    var author: String?
    var createdAt: Date
    var paletteModels: [ColorModel]
    var pixels: [PixelData]
    
    var palette: [UIColor] { return paletteModels.map { $0.toUIColor } }
    var maxDimension: Int { max(gridWidth, gridHeight) }
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, gridWidth, gridHeight, author, createdAt, palette, pixelsNumber
    }
    
    // --- Init: Tạo level mới từ App ---
    // [MỚI] Thêm tham số category vào init
    init(id: String? = nil, name: String, category: String = Category.others.rawValue, gridWidth: Int, gridHeight: Int, pixels: [PixelData], paletteModels: [ColorModel], author: String? = "User") {
        self.id = id
        self.name = name
        self.category = category
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.pixels = pixels
        self.paletteModels = paletteModels
        self.author = author
        self.createdAt = Date()
    }
    
    // --- DECODER: Tải từ Firebase về ---
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decode(DocumentID<String>.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // [MỚI] Nếu dữ liệu cũ trên Firebase chưa có category, mặc định là "Khác"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? Category.others.rawValue
        
        gridWidth = try container.decode(Int.self, forKey: .gridWidth)
        gridHeight = try container.decode(Int.self, forKey: .gridHeight)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        paletteModels = try container.decode([ColorModel].self, forKey: .palette)
        
        let pixelsNumber = try container.decode([Int].self, forKey: .pixelsNumber)
        
        // ... (Logic tái tạo PixelData giữ nguyên như cũ) ...
        var loadedPixels: [PixelData] = []
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let index = y * gridWidth + x
                if index < pixelsNumber.count {
                    let number = pixelsNumber[index]
                    if number == 0 {
                        loadedPixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r: 1, g: 1, b: 1), isColored: true))
                        continue
                    }
                    let colorIndex = number - 1
                    let rawColor = (colorIndex >= 0 && colorIndex < paletteModels.count) ? paletteModels[colorIndex] : ColorModel(r: 0, g: 0, b: 0)
                    loadedPixels.append(PixelData(x: x, y: y, number: number, rawColor: rawColor, isColored: false))
                }
            }
        }
        self.pixels = loadedPixels
    }
    
    // --- ENCODER: Đẩy lên Firebase ---
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category) // [MỚI] Lưu category lên Cloud
        try container.encode(gridWidth, forKey: .gridWidth)
        try container.encode(gridHeight, forKey: .gridHeight)
        try container.encode(author, forKey: .author)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(paletteModels, forKey: .palette)
        let pixelsNumber = pixels.map { $0.number }
        try container.encode(pixelsNumber, forKey: .pixelsNumber)
    }
    
    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        return lhs.id == rhs.id && lhs.pixels == rhs.pixels
    }
}
