import UIKit
import FirebaseFirestore

enum Category: String, CaseIterable, Codable {
    case animals = "Động vật"
    case food = "Đồ ăn"
    case scenery = "Phong cảnh"
    case characters = "Nhân vật"
    case others = "Khác"
}

struct LevelData: Identifiable, Codable, Equatable {
    
    var id: String
    var name: String
    var category: String
    var isLocked: Bool
    
    var gridWidth: Int
    var gridHeight: Int
    var author: String?
    var createdAt: Date
    
    var timeSpent: TimeInterval = 0
    
    // [THÊM MỚI]
    var groupId: String // ID chung để gom nhóm 3 cấp độ
    var difficulty: Int // 1: Easy, 2: Medium, 3: Hard
    
    var paletteModels: [ColorModel]
    var pixels: [PixelData]
    
    var palette: [UIColor] {
        return paletteModels.map { $0.toUIColor }
    }
    
    var progress: Float {
        let total = pixels.filter { $0.number > 0 }.count
        if total == 0 { return 0 }
        let colored = pixels.filter { $0.isColored }.count
        return Float(colored) / Float(total)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, isLocked, gridWidth, gridHeight, author, createdAt, palette
        case pixelsNumber, coloredIndices, timeSpent
        case groupId, difficulty // [MỚI]
    }
    
    // --- INIT ---
    init(id: String = UUID().uuidString,
         name: String,
         category: String = Category.others.rawValue,
         isLocked: Bool = false,
         gridWidth: Int,
         gridHeight: Int,
         pixels: [PixelData],
         paletteModels: [ColorModel],
         author: String? = "User",
         timeSpent: TimeInterval = 0,
         groupId: String? = nil, // [MỚI] Optional để tương thích code cũ
         difficulty: Int = 1) {  // [MỚI] Mặc định là Easy
        
        self.id = id
        self.name = name
        self.category = category
        self.isLocked = isLocked
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.pixels = pixels
        self.paletteModels = paletteModels
        self.author = author
        self.createdAt = Date()
        self.timeSpent = timeSpent
        
        // Nếu không có groupId (level cũ), dùng chính id làm groupId
        self.groupId = groupId ?? id
        self.difficulty = difficulty
    }
    
    // --- DECODER ---
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? Category.others.rawValue
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        gridWidth = try container.decode(Int.self, forKey: .gridWidth)
        gridHeight = try container.decode(Int.self, forKey: .gridHeight)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        paletteModels = try container.decode([ColorModel].self, forKey: .palette)
        timeSpent = try container.decodeIfPresent(TimeInterval.self, forKey: .timeSpent) ?? 0
        
        // [MỚI] Decode groupId và difficulty với giá trị mặc định cho dữ liệu cũ
        groupId = try container.decodeIfPresent(String.self, forKey: .groupId) ?? id
        difficulty = try container.decodeIfPresent(Int.self, forKey: .difficulty) ?? 1
        
        let pixelsNumber = try container.decode([Int].self, forKey: .pixelsNumber)
        let coloredIndices = try container.decodeIfPresent(Set<Int>.self, forKey: .coloredIndices) ?? []
        
        var loadedPixels: [PixelData] = []
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let index = y * gridWidth + x
                if index < pixelsNumber.count {
                    let number = pixelsNumber[index]
                    if number == 0 {
                        loadedPixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r: 1, g: 1, b: 1), isColored: true))
                    } else {
                        let isColored = coloredIndices.contains(index)
                        let colorIndex = number - 1
                        let rawColor = (colorIndex >= 0 && colorIndex < paletteModels.count) ? paletteModels[colorIndex] : ColorModel(r: 0, g: 0, b: 0)
                        loadedPixels.append(PixelData(x: x, y: y, number: number, rawColor: rawColor, isColored: isColored))
                    }
                }
            }
        }
        self.pixels = loadedPixels
    }
    
    // --- ENCODER ---
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(gridWidth, forKey: .gridWidth)
        try container.encode(gridHeight, forKey: .gridHeight)
        try container.encode(author, forKey: .author)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(paletteModels, forKey: .palette)
        try container.encode(timeSpent, forKey: .timeSpent)
        
        // [MỚI] Encode trường mới
        try container.encode(groupId, forKey: .groupId)
        try container.encode(difficulty, forKey: .difficulty)
        
        let pixelsNumber = pixels.map { $0.number }
        try container.encode(pixelsNumber, forKey: .pixelsNumber)
        
        let coloredIndices = pixels.enumerated()
            .filter { $0.element.number > 0 && $0.element.isColored }
            .map { $0.offset }
        try container.encode(coloredIndices, forKey: .coloredIndices)
    }
    
    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        return lhs.id == rhs.id && lhs.pixels == rhs.pixels && lhs.isLocked == rhs.isLocked
    }
}
