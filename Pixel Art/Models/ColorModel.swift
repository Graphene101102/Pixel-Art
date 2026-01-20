import UIKit

struct ColorModel: Codable, Hashable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    
    var toUIColor: UIColor {
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // Hashable protocol (để dùng làm Key trong Dictionary)
        func hash(into hasher: inout Hasher) {
            hasher.combine(r)
            hasher.combine(g)
            hasher.combine(b)
        }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
