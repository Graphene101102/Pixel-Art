import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // Lưu một level mới lên Cloud
    func uploadLevel(level: LevelData, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection("levels").addDocument(from: level)
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
                    print("Lỗi tải dữ liệu level")
                    completion([])
                    return
                }
                let levels = documents.compactMap { doc -> LevelData? in
                    return try? doc.data(as: LevelData.self)
                }
                completion(levels)
            }
    }
    
    // [MỚI] Tải danh sách danh mục từ collection "categories"
    // Collection này trên Firebase cần có các document, mỗi document có field "name": "Tên danh mục"
    func fetchCategories(completion: @escaping ([String]) -> Void) {
        db.collection("categories").order(by: "name").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Lỗi tải category hoặc chưa có collection 'categories'")
                completion([])
                return
            }
            
            let categories = documents.compactMap { doc -> String? in
                return doc.data()["name"] as? String
            }
            completion(categories)
        }
    }
}
