import CoreGraphics
import UIKit
import Vision
import CoreImage

class ImageProcessor {
    static let shared = ImageProcessor()
    
    // Ngưỡng so sánh màu trong không gian Lab (Delta E)
    private let colorSimilarityThreshold: CGFloat = 10.0
    private let maxPaletteColors = 16
    
    // [THAY ĐỔI 1] Đặt false để KHÔNG bỏ qua nền trắng.
    // Màu trắng sẽ được coi là một màu cần tô.
    private let ignoreWhiteBackground: Bool = false

    func processImage(image: UIImage, imageId: String, targetDimension: Int = 48) -> LevelData? {
        // 1. Resize ảnh
        let targetSize = calculateAspectCorrectSize(originalSize: image.size, targetDimension: targetDimension)
        guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else { return nil }
        
        // 2. Trích xuất dữ liệu RGBA
        guard let (pixelData, width, height) = getRGBABytes(from: resizedImage) else { return nil }
        
        var pixels: [PixelData] = []
        var paletteModels: [ColorModel] = []
        var paletteLabs: [(l: CGFloat, a: CGFloat, b: CGFloat)] = []
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                
                // Đọc Alpha
                let alpha = CGFloat(pixelData[offset + 3]) / 255.0
                
                // --- [XỬ LÝ TRONG SUỐT] ---
                // Nếu độ trong suốt thấp (< 10%) -> Coi là ô trống, đã hoàn thành
                if alpha < 0.1 {
                    // Number = 0: Quy ước là trong suốt/không có số
                    // isColored = true: Coi như đã tô xong để không tính vào tiến độ game
                    pixels.append(PixelData(
                        x: x, y: y,
                        number: 0,
                        rawColor: ColorModel(r: 0, g: 0, b: 0), // Màu raw không quan trọng vì number=0
                        isColored: true
                    ))
                    continue
                }

                // Đọc RGB
                var r = CGFloat(pixelData[offset]) / 255.0
                var g = CGFloat(pixelData[offset + 1]) / 255.0
                var b = CGFloat(pixelData[offset + 2]) / 255.0
                
                // Un-multiply Alpha để lấy màu gốc (đặc biệt quan trọng với viền mờ)
                if alpha > 0 && alpha < 1.0 {
                    r = min(1.0, r / alpha)
                    g = min(1.0, g / alpha)
                    b = min(1.0, b / alpha)
                }
                
                // --- [XỬ LÝ MÀU TRẮNG VÀ CÁC MÀU KHÁC] ---
                // Ở đây KHÔNG có lệnh "continue" nếu gặp màu trắng.
                // Màu trắng sẽ chảy xuống thuật toán bên dưới để được thêm vào Palette.
                
                let currentRawColor = ColorModel(r: r, g: g, b: b)
                let currentLab = rgbToLab(r: r, g: g, b: b)
                
                // --- THUẬT TOÁN GỘP MÀU (CIELAB) ---
                var finalIndex: Int
                var finalColorModel: ColorModel

                if let match = findClosestMatchLab(targetLab: currentLab, paletteLabs: paletteLabs, threshold: colorSimilarityThreshold) {
                    finalIndex = match.index
                    finalColorModel = paletteModels[finalIndex]
                } else {
                    if paletteModels.count < maxPaletteColors {
                        paletteModels.append(currentRawColor)
                        paletteLabs.append(currentLab)
                        finalIndex = paletteModels.count - 1
                        finalColorModel = currentRawColor
                    } else {
                        let closest = findClosestMatchLab(targetLab: currentLab, paletteLabs: paletteLabs, threshold: 99999.0)!
                        finalIndex = closest.index
                        finalColorModel = paletteModels[finalIndex]
                    }
                }
                
                // Number > 0: Là màu trong palette (bao gồm cả màu trắng)
                // isColored = false: Người chơi PHẢI tô ô này
                let number = finalIndex + 1
                pixels.append(PixelData(
                    x: x, y: y,
                    number: number,
                    rawColor: finalColorModel,
                    isColored: false
                ))
            }
        }
        
        return LevelData(
                id: imageId, // [QUAN TRỌNG] ID để lưu file
                name: "Pixel Art",
                gridWidth: width,
                gridHeight: height,
                pixels: pixels,
                paletteModels: paletteModels
            )
    }
    
    // --- CÁC HÀM HỖ TRỢ (GIỮ NGUYÊN) ---

    private func rgbToLab(r: CGFloat, g: CGFloat, b: CGFloat) -> (l: CGFloat, a: CGFloat, b: CGFloat) {
        func pivot(_ n: CGFloat) -> CGFloat {
            return (n > 0.04045) ? pow((n + 0.055) / 1.055, 2.4) : n / 12.92
        }
        let rLin = pivot(r), gLin = pivot(g), bLin = pivot(b)

        let x = (rLin * 0.4124 + gLin * 0.3576 + bLin * 0.1805) * 100.0
        let y = (rLin * 0.2126 + gLin * 0.7152 + bLin * 0.0722) * 100.0
        let z = (rLin * 0.0193 + gLin * 0.1192 + bLin * 0.9505) * 100.0

        func pivotXYZ(_ n: CGFloat) -> CGFloat {
            return (n > 0.008856) ? pow(n, 1.0/3.0) : (7.787 * n) + (16.0 / 116.0)
        }
        
        let xn: CGFloat = 95.047, yn: CGFloat = 100.000, zn: CGFloat = 108.883
        let l = 116.0 * pivotXYZ(y / yn) - 16.0
        let a = 500.0 * (pivotXYZ(x / xn) - pivotXYZ(y / yn))
        let bVal = 200.0 * (pivotXYZ(y / yn) - pivotXYZ(z / zn))

        return (l, a, bVal)
    }

    private func findClosestMatchLab(targetLab: (l: CGFloat, a: CGFloat, b: CGFloat), paletteLabs: [(l: CGFloat, a: CGFloat, b: CGFloat)], threshold: CGFloat) -> (index: Int, distance: CGFloat)? {
        var bestMatch: (Int, CGFloat)? = nil
        var minDistance: CGFloat = threshold
        
        for (index, lab) in paletteLabs.enumerated() {
            let dL = targetLab.l - lab.l
            let da = targetLab.a - lab.a
            let db = targetLab.b - lab.b
            let dist = sqrt(dL*dL + da*da + db*db)
            
            if dist < minDistance {
                minDistance = dist
                bestMatch = (index, dist)
            }
        }
        return bestMatch
    }
    
    private func getRGBABytes(from image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width, height = cgImage.height
        let bytesPerRow = 4 * width
        let totalBytes = height * bytesPerRow
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(data: &pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        return (pixelData, width, height)
    }

    private func calculateAspectCorrectSize(originalSize: CGSize, targetDimension: Int) -> CGSize {
        let width = originalSize.width, height = originalSize.height
        let target = CGFloat(targetDimension)
        if width > height {
            let newHeight = target * (height / width)
            return CGSize(width: target, height: round(newHeight))
        } else {
            let newWidth = target * (width / height)
            return CGSize(width: round(newWidth), height: target)
        }
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false // Giữ alpha channel
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .none
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
