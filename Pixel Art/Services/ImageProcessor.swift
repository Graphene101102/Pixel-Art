import CoreGraphics
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessor {
    static let shared = ImageProcessor()
    
    private let colorSimilarityThreshold: CGFloat = 0.12
    private let maxPaletteColors = 12
    
    private let ignoreWhiteBackground: Bool = true

    func processImage(image: UIImage, targetDimension: Int = 48) -> LevelData? {
        // 1. Tính toán kích thước mới giữ tỷ lệ
        let targetSize = calculateAspectCorrectSize(originalSize: image.size, targetDimension: targetDimension)
        
        // 2. Resize ảnh về kích thước nhỏ
        guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else { return nil }
        
        // 3. Trích xuất dữ liệu byte theo chuẩn RGBA
        guard let (pixelData, width, height) = getRGBABytes(from: resizedImage) else {
            print("Lỗi không thể trích xuất dữ liệu RGBA")
            return nil
        }
        
        var pixels: [PixelData] = []
        var paletteModels: [ColorModel] = []
        
        let bytesPerPixel = 4 // R, G, B, A
        let bytesPerRow = bytesPerPixel * width
        
        // 4. Duyệt loop xử lý pixel
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                
                // Đọc kênh Alpha (byte thứ 4)
                let alpha = CGFloat(pixelData[offset + 3]) / 255.0
                
                if alpha < 0.1 {
                    // Trong suốt -> Nền trắng
                    pixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r:0,g:0,b:0), isColored: true))
                    continue
                }

                // Byte 0 là R, Byte 1 là G, Byte 2 là B
                var r = CGFloat(pixelData[offset]) / 255.0
                var g = CGFloat(pixelData[offset + 1]) / 255.0
                var b = CGFloat(pixelData[offset + 2]) / 255.0
                
                if alpha > 0 {
                    r = min(1.0, r / alpha)
                    g = min(1.0, g / alpha)
                    b = min(1.0, b / alpha)
                }
                
                //Nếu ảnh mất alpha
                if ignoreWhiteBackground {
                    if r > 0.95 && g > 0.95 && b > 0.95 {
                        pixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r: 0, g: 0, b: 0), isColored: true))
                        continue
                    }
                }
                
                let currentRawColor = ColorModel(r: r, g: g, b: b)
                
                // --- THUẬT TOÁN GỘP MÀU ---
                var finalIndex: Int
                var finalColorModel: ColorModel

                if let match = findClosestMatch(target: currentRawColor, palette: paletteModels, threshold: colorSimilarityThreshold) {
                    finalIndex = match.index
                    finalColorModel = paletteModels[finalIndex]
                } else {
                    if paletteModels.count < maxPaletteColors {
                        paletteModels.append(currentRawColor)
                        finalIndex = paletteModels.count - 1
                        finalColorModel = currentRawColor
                    } else {
                        let closest = findClosestMatch(target: currentRawColor, palette: paletteModels, threshold: 1.0)!
                        finalIndex = closest.index
                        finalColorModel = paletteModels[finalIndex]
                    }
                }
                
                let number = finalIndex + 1
                pixels.append(PixelData(x: x, y: y, number: number, rawColor: finalColorModel, isColored: false))
            }
        }
        
        print("Xử lý xong: \(width)x\(height), palette: \(paletteModels.count) màu")
        
        return LevelData(name: "New Level", gridWidth: width, gridHeight: height, pixels: pixels, paletteModels: paletteModels)
    }
    
    // Lấy màu
    private func getRGBABytes(from image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow
        
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        return (pixelData, width, height)
    }

    //Tính khoảng đến các màu
    private func calculateAspectCorrectSize(originalSize: CGSize, targetDimension: Int) -> CGSize {
        let width = originalSize.width
        let height = originalSize.height
        let target = CGFloat(targetDimension)
        if width > height {
            let newHeight = target * (height / width)
            return CGSize(width: target, height: round(newHeight))
        } else {
            let newWidth = target * (width / height)
            return CGSize(width: round(newWidth), height: target)
        }
    }

    //Kiểm tra màu gần giống nhất
    private func findClosestMatch(target: ColorModel, palette: [ColorModel], threshold: CGFloat) -> (index: Int, distance: CGFloat)? {
        var bestMatch: (Int, CGFloat)? = nil
        var minDistance: CGFloat = threshold
        for (index, color) in palette.enumerated() {
            let dist = distance(c1: target, c2: color)
            if dist < minDistance {
                minDistance = dist
                bestMatch = (index, dist)
            }
        }
        return bestMatch
    }
    
    private func distance(c1: ColorModel, c2: ColorModel) -> CGFloat {
        let dr = c1.r - c2.r
        let dg = c1.g - c2.g
        let db = c1.b - c2.b
        return sqrt(dr*dr + dg*dg + db*db)
    }
    
    // Hàm resize
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .none
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
