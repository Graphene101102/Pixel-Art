import Foundation

class GameStorageManager {
    static let shared = GameStorageManager()
    
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - SAVE
    func saveLevelProgress(_ level: LevelData) {
        // Lưu chạy ngầm
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(level)
                // Đặt tên file theo ID duy nhất của level
                let fileName = "progress_\(level.id).json"
                let fileURL = self.documentsDirectory.appendingPathComponent(fileName)
                try data.write(to: fileURL)
            } catch {
                print("❌ Lỗi lưu file: \(error)")
            }
        }
    }
    
    // MARK: - LOAD & MERGE
    func loadLevelProgress(originalLevel: LevelData) -> LevelData {
        let fileName = "progress_\(originalLevel.id).json"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            // 1. Thử đọc file từ máy
            let data = try Data(contentsOf: fileURL)
            var savedLevel = try JSONDecoder().decode(LevelData.self, from: data)
            
            // 2. Cập nhật các thông tin tĩnh từ Firebase vào bản Save cũ
            savedLevel.name = originalLevel.name
            savedLevel.category = originalLevel.category
            savedLevel.paletteModels = originalLevel.paletteModels // Cập nhật bảng màu nếu Firebase đổi
            
            // 3. Đồng bộ trạng thái mở khóa (Unlock vĩnh viễn)
            if isLevelUnlocked(id: originalLevel.id) {
                savedLevel.isLocked = false
            } else {
                // Nếu chưa mở khóa vĩnh viễn, giữ nguyên trạng thái lock gốc của Firebase
                savedLevel.isLocked = originalLevel.isLocked
            }
            
            return savedLevel
        } catch {
            // 3. Nếu không có file save (hoặc lỗi), trả về level gốc từ Firebase
            // Đồng thời kiểm tra xem nó có được mở khóa vĩnh viễn chưa
            var level = originalLevel
            if isLevelUnlocked(id: level.id) {
                level.isLocked = false
            }
            return level
        }
    }
    
    func markLevelAsUnlocked(id: String) {
        var unlockedIDs = UserDefaults.standard.stringArray(forKey: "unlockedLevels") ?? []
        if !unlockedIDs.contains(id) {
            unlockedIDs.append(id)
            UserDefaults.standard.set(unlockedIDs, forKey: "unlockedLevels")
        }
    }
    
    func isLevelUnlocked(id: String) -> Bool {
        let unlockedIDs = UserDefaults.standard.stringArray(forKey: "unlockedLevels") ?? []
        return unlockedIDs.contains(id)
    }
    
    func loadAllLocalLevels() -> [LevelData] {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            var levels: [LevelData] = []
            for url in fileURLs {
                if url.pathExtension == "json" {
                    if let data = try? Data(contentsOf: url),
                       let level = try? JSONDecoder().decode(LevelData.self, from: data) {
                        levels.append(level)
                    }
                }
            }
            // Sắp xếp mặc định: Mới nhất lên đầu
            return levels.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            return []
        }
    }
    
}
