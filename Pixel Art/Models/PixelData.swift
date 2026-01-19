import UIKit

struct PixelData: Equatable, Codable {
    let x, y: Int
    var number: Int 
    let rawColor: ColorModel
    var isColored: Bool
}
