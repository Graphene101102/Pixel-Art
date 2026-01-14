import UIKit

extension UIColor {
    // Chuyển UIColor sang Hex Int (ví dụ: 0xFF0000)
    var toHex: Int {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
    }

    // Khởi tạo từ Hex Int
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
