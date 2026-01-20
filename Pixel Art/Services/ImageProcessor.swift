import CoreGraphics
import UIKit
import Vision
import CoreImage

struct RawImageData {
    let pixelData: [UInt8]
    let width: Int
    let height: Int
}

class ImageProcessor {
    static let shared = ImageProcessor()
    
    // Không fix cứng threshold nữa vì ta sẽ thay đổi nó động
    private let initialThreshold: CGFloat = 100.0 // Bắt đầu với khoảng cách rất xa
    private let minThreshold: CGFloat = 5.0       // Khoảng cách tối thiểu
    private let thresholdStep: CGFloat = 5.0      // Bước giảm mỗi lần lặp
    
    // MARK: - BƯỚC 1: Xử lý thô (Giữ nguyên chuẩn RGBA)
    func prepareImageData(image: UIImage, targetDimension: Int = 48) -> RawImageData? {
        let targetSize = calculateAspectCorrectSize(originalSize: image.size, targetDimension: targetDimension)
        guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else { return nil }
        guard let (pixelData, width, height) = getStandardRGBABytes(from: resizedImage) else { return nil }
        return RawImageData(pixelData: pixelData, width: width, height: height)
    }

    // MARK: - BƯỚC 2: Tạo Level (Logic Thông Minh Mới)
    func generateLevelFromRawData(rawData: RawImageData, imageId: String, groupId: String, difficulty: Int, maxColors: Int) -> LevelData {
        
        let width = rawData.width
        let height = rawData.height
        let pixelData = rawData.pixelData
        let bytesPerRow = 4 * width
        
        // --- GIAI ĐOẠN A: Thống kê tần suất màu (Histogram) ---
        // Mục đích: Tìm ra những màu nào xuất hiện nhiều nhất trong ảnh
        var colorFrequency: [ColorModel: Int] = [:]
        
        // Mảng lưu tạm màu của từng pixel để dùng cho bước sau đỡ phải tính lại
        var rawPixelGrid: [ColorModel?] = Array(repeating: nil, count: width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * 4)
                if offset + 3 >= pixelData.count { continue }
                
                let a_raw = CGFloat(pixelData[offset + 3])
                let alpha = a_raw / 255.0
                
                // Nếu trong suốt -> Bỏ qua
                if alpha < 0.1 { continue }
                
                let r_raw = CGFloat(pixelData[offset])
                let g_raw = CGFloat(pixelData[offset + 1])
                let b_raw = CGFloat(pixelData[offset + 2])
                
                var r = r_raw / 255.0
                var g = g_raw / 255.0
                var b = b_raw / 255.0
                
                if alpha > 0 && alpha < 1.0 {
                    r = min(1.0, r / alpha); g = min(1.0, g / alpha); b = min(1.0, b / alpha)
                }
                
                // Làm tròn màu một chút để gom nhóm tốt hơn (giảm nhiễu)
                // Ví dụ: 0.1234 -> 0.12
                let precision: CGFloat = 100.0
                r = round(r * precision) / precision
                g = round(g * precision) / precision
                b = round(b * precision) / precision
                
                let color = ColorModel(r: r, g: g, b: b)
                
                // Lưu vào grid tạm
                rawPixelGrid[y * width + x] = color
                
                // Đếm tần suất
                colorFrequency[color, default: 0] += 1
            }
        }
        
        // Sắp xếp các màu theo độ phổ biến (Nhiều nhất lên đầu)
        // Chỉ lấy Top 1000 màu phổ biến để thuật toán chạy nhanh
        let sortedUniqueColors = colorFrequency.keys.sorted { colorFrequency[$0]! > colorFrequency[$1]! }.prefix(1000)
        
        // --- GIAI ĐOẠN B: Tìm Palette tối ưu (Iterative Threshold) ---
        var finalPalette: [ColorModel] = []
        var currentThreshold = initialThreshold // Bắt đầu từ 100 (rất xa)
        
        // Vòng lặp: Giảm dần threshold cho đến khi tìm đủ số màu
        while currentThreshold >= minThreshold {
            finalPalette.removeAll()
            var paletteLabs: [(l: CGFloat, a: CGFloat, b: CGFloat)] = []
            
            for candidate in sortedUniqueColors {
                // Nếu bảng màu đã đủ -> Dừng ngay
                if finalPalette.count >= maxColors { break }
                
                let candidateLab = rgbToLab(r: candidate.r, g: candidate.g, b: candidate.b)
                
                // Kiểm tra xem màu này có "quá gần" với bất kỳ màu nào đã chọn không
                var isDistinct = true
                for existingLab in paletteLabs {
                    let dL = candidateLab.l - existingLab.l
                    let da = candidateLab.a - existingLab.a
                    let db = candidateLab.b - existingLab.b
                    let dist = sqrt(dL*dL + da*da + db*db)
                    
                    if dist < currentThreshold {
                        isDistinct = false
                        break
                    }
                }
                
                // Nếu khác biệt, thêm vào palette
                if isDistinct {
                    finalPalette.append(candidate)
                    paletteLabs.append(candidateLab)
                }
            }
            
            // Nếu đã tìm đủ số lượng màu mong muốn (hoặc gần đủ), thì chấp nhận Palette này
            // Ví dụ: Cần 10 màu, tìm được 8-10 màu là OK.
            if finalPalette.count >= maxColors {
                break
            }
            
            // Nếu chưa đủ, giảm threshold để chấp nhận các màu gần nhau hơn
            currentThreshold -= thresholdStep
        }
        
        // Fallback: Nếu chạy hết vòng lặp mà vẫn chưa đủ màu (ảnh quá đơn điệu),
        // thì ta vẫn dùng finalPalette hiện có.
        
        // Chuẩn bị Labs cache để map lại pixel
        let finalPaletteLabs = finalPalette.map { rgbToLab(r: $0.r, g: $0.g, b: $0.b) }
        
        // --- GIAI ĐOẠN C: Map lại từng Pixel vào Palette đã chọn ---
        var pixels: [PixelData] = []
        
        for y in 0..<height {
            for x in 0..<width {
                // Lấy màu gốc từ grid tạm (đã tính ở Giai đoạn A)
                guard let originalColor = rawPixelGrid[y * width + x] else {
                    // Ô trong suốt
                    pixels.append(PixelData(x: x, y: y, number: 0, rawColor: ColorModel(r: 1, g: 1, b: 1), isColored: true))
                    continue
                }
                
                // Tìm màu gần nhất trong Final Palette
                let originalLab = rgbToLab(r: originalColor.r, g: originalColor.g, b: originalColor.b)
                
                // Tìm match chính xác nhất (Threshold cực lớn để chắc chắn tìm được)
                if let match = findClosestMatchLab(targetLab: originalLab, paletteLabs: finalPaletteLabs, threshold: 99999.0) {
                    let number = match.index + 1
                    let paletteColor = finalPalette[match.index]
                    pixels.append(PixelData(x: x, y: y, number: number, rawColor: paletteColor, isColored: false))
                } else {
                    // Trường hợp hiếm hoi (không xảy ra), map về màu 1
                    pixels.append(PixelData(x: x, y: y, number: 1, rawColor: finalPalette.first ?? originalColor, isColored: false))
                }
            }
        }
        
        return LevelData(
            id: imageId,
            name: "Pixel Art",
            gridWidth: width,
            gridHeight: height,
            pixels: pixels,
            paletteModels: finalPalette,
            groupId: groupId,
            difficulty: difficulty
        )
    }
    
    // MARK: - [GIỮ NGUYÊN] Các hàm hỗ trợ chuẩn (không đổi)
    private func getStandardRGBABytes(from image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = 4 * width
        let totalBytes = height * bytesPerRow
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
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
        format.opaque = false
        if #available(iOS 12.0, *) { format.preferredRange = .standard }
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func rgbToLab(r: CGFloat, g: CGFloat, b: CGFloat) -> (l: CGFloat, a: CGFloat, b: CGFloat) {
        func pivot(_ n: CGFloat) -> CGFloat { return (n > 0.04045) ? pow((n + 0.055) / 1.055, 2.4) : n / 12.92 }
        let rLin = pivot(r), gLin = pivot(g), bLin = pivot(b)
        let x = (rLin * 0.4124 + gLin * 0.3576 + bLin * 0.1805) * 100.0
        let y = (rLin * 0.2126 + gLin * 0.7152 + bLin * 0.0722) * 100.0
        let z = (rLin * 0.0193 + gLin * 0.1192 + bLin * 0.9505) * 100.0
        func pivotXYZ(_ n: CGFloat) -> CGFloat { return (n > 0.008856) ? pow(n, 1.0/3.0) : (7.787 * n) + (16.0 / 116.0) }
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
}
