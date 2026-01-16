import UIKit

struct ColorModel: Codable, Hashable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    var toUIColor: UIColor {
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
