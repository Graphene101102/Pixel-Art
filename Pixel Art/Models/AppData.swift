import Foundation

class AppData {
    static let shared = AppData()
    private init() {}
    
    var preloadedLevels: [LevelData] = []
    var preloadedCategories: [String] = []
    var hasDataLoaded: Bool = false
}
