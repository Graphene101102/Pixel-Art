import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // Lưu một level mới lên Cloud
    func uploadLevel(level: LevelData, completion: @escaping (Bool) -> Void) {
        let model = LevelModel(from: level)
        
        do {
            // Lưu vào collection tên là "levels"
            try db.collection("levels").addDocument(from: model)
            print("Đã upload thành công!")
            completion(true)
        } catch {
            print("Lỗi upload: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Tải danh sách level từ Cloud về
    func fetchLevels(completion: @escaping ([LevelData]) -> Void) {
        db.collection("levels")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Lỗi tải dữ liệu")
                    completion([])
                    return
                }
                
                // Map từng document thành LevelModel -> rồi thành LevelData
                let levels = documents.compactMap { doc -> LevelData? in
                    if let model = try? doc.data(as: LevelModel.self) {
                        return LevelData(from: model)
                    }
                    return nil
                }
                
                completion(levels)
            }
    }
}
