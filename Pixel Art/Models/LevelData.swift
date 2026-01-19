import UIKit
import FirebaseFirestore

// MARK: - Category Enum
enum Category: String, CaseIterable, Codable {
    case animals = "Động vật"
    case food = "Đồ ăn"
    case scenery = "Phong cảnh"
    case characters = "Nhân vật"
    case others = "Khác"
}

// MARK: - LevelData
struct LevelData: Identifiable, Codable, Equatable {
    
    // Sử dụng String thường thay vì @DocumentID để tránh lỗi Codable khi lưu file local
    var id: String
    var name: String
    var category: String
    var isLocked: Bool
    
    var gridWidth: Int
    var gridHeight: Int
    var author: String?
    var createdAt: Date
    
    var paletteModels: [ColorModel]
    var pixels: [PixelData]
    
    // Helper để lấy Palette dạng UIColor
    var palette: [UIColor] {
        return paletteModels.map { $0.toUIColor }
    }
    
    // Helper: Tính toán % hoàn thành để hiển thị
        var progress: Float {
            let total = pixels.filter { $0.number > 0 }.count
            if total == 0 { return 0 }
            let colored = pixels.filter { $0.isColored }.count
            return Float(colored) / Float(total)
        }
    
    // CodingKeys: Định nghĩa tên key khi lưu vào JSON/Firestore
    enum CodingKeys: String, CodingKey {
            case id, name, category, isLocked, gridWidth, gridHeight, author, createdAt, palette
            case pixelsNumber
            case coloredIndices
        }
    
    // --- INIT: Tạo level mới từ App ---
    init(id: String = UUID().uuidString,
         name: String,
         category: String = Category.others.rawValue,
         isLocked: Bool = false,
         gridWidth: Int,
         gridHeight: Int,
         pixels: [PixelData],
         paletteModels: [ColorModel],
         author: String? = "User") {
        
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
    }
    
    // --- DECODER: Tải từ Firebase hoặc Local File ---
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 1. Decode các thuộc tính cơ bản
        // Sử dụng decodeIfPresent ?? default để tránh crash nếu dữ liệu cũ thiếu trường
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? Category.others.rawValue
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        
        gridWidth = try container.decode(Int.self, forKey: .gridWidth)
        gridHeight = try container.decode(Int.self, forKey: .gridHeight)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        paletteModels = try container.decode([ColorModel].self, forKey: .palette)
        
        // 2. Decode mảng số (pixelsNumber) và tái tạo lại [PixelData]
        let pixelsNumber = try container.decode([Int].self, forKey: .pixelsNumber)
        
        // 3. Lấy danh sách tiến độ (những ô đã tô) từ Local Storage. Nếu load từ firebase, field này sẽ rỗng
        let coloredIndices = try container.decodeIfPresent(Set<Int>.self, forKey: .coloredIndices) ?? []
        
        var loadedPixels: [PixelData] = []
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let index = y * gridWidth + x
                
                // Kiểm tra an toàn index
                if index < pixelsNumber.count {
                    let number = pixelsNumber[index]
                    
                    if number == 0 {
                        // Ô trong suốt/trống
                        loadedPixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r: 1, g: 1, b: 1), isColored: true))
                    } else {
                        let isColored = coloredIndices.contains(index)
                        // Ô màu
                        let colorIndex = number - 1
                        // Lấy màu từ palette
                        let rawColor = (colorIndex >= 0 && colorIndex < paletteModels.count) ? paletteModels[colorIndex] : ColorModel(r: 0, g: 0, b: 0)
                        
                        // Mặc định isColored là false khi load từ template.
                        loadedPixels.append(PixelData(x: x, y: y, number: number, rawColor: rawColor, isColored: isColored))
                    }
                }
            }
        }
        self.pixels = loadedPixels
    }
    
    // --- ENCODER: Lưu xuống Firebase hoặc Local File ---
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
        
        // Nén [PixelData] thành mảng [Int] để tiết kiệm dung lượng
        // Chỉ lưu số thứ tự màu (number), không lưu tọa độ hay trạng thái isColored
        // (Trạng thái isColored cho file save game sẽ được xử lý riêng nếu cần,
        // hoặc dùng chính logic này nếu muốn lưu file save game dạng nén)
        let pixelsNumber = pixels.map { $0.number }
        try container.encode(pixelsNumber, forKey: .pixelsNumber)
        
        // Lưu danh sách các ô ĐÃ TÔ MÀU
        // Chỉ lưu index của những ô có màu (number > 0) mà người dùng đã tô xong (isColored == true)
        let coloredIndices = pixels.enumerated()
            .filter { $0.element.number > 0 && $0.element.isColored }
            .map { $0.offset }
        
        try container.encode(coloredIndices, forKey: .coloredIndices)
    }
    
    static func == (lhs: LevelData, rhs: LevelData) -> Bool {
        return lhs.id == rhs.id && lhs.pixels == rhs.pixels && lhs.isLocked == rhs.isLocked
    }
}
