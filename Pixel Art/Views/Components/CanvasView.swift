import UIKit

// MARK: - CANVAS VIEW
class CanvasView: UIView, UIScrollViewDelegate {
    
    // 1. SCROLL VIEW
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 0.5
        sv.maximumZoomScale = 10.0
        sv.bouncesZoom = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        
        // [QUAN TRỌNG] Cho phép nảy (bounce) để cảm giác vuốt mượt mà hơn
        sv.alwaysBounceHorizontal = true
        sv.alwaysBounceVertical = true
        
        // Tắt tự động chỉnh inset của iOS để ta tự quản lý
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    // 2. CONTAINER
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    
    private let drawingLayer = NumberOverlayView()
    private var level: LevelData?
    
    private var lastZoomStep: Int = 0
    
    var scrollViewPanGesture: UIPanGestureRecognizer {
        return scrollView.panGestureRecognizer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        scrollView.addSubview(containerView)
        
        drawingLayer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(drawingLayer)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            drawingLayer.topAnchor.constraint(equalTo: containerView.topAnchor),
            drawingLayer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            drawingLayer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            drawingLayer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    // MARK: - RENDER
    func render(level: LevelData, currentNumber: Int, redraw: Bool = true) {
        let levelChanged = self.level?.id != level.id
        self.level = level
        
        if levelChanged {
            // Reset layout khi đổi màn chơi mới
            updateContainerSize(gridW: level.gridWidth, gridH: level.gridHeight)
            // Zoom vừa khít màn hình lúc đầu
            resetView()
            lastZoomStep = 0
        }
        
        drawingLayer.contentScaleFactor = 7.0
        drawingLayer.update(level: level, currentNumber: currentNumber, currentZoom: scrollView.zoomScale)
        
        if redraw {
            drawingLayer.setNeedsDisplay()
        }
    }
    
    func resetView() {
        // Zoom về 1.0 (hoặc mức fit màn hình tùy logic)
        scrollView.setZoomScale(1.0, animated: true)
    }
    
    // Thêm khoảng đệm (Padding) để di chuyển thoải mái
    private func updateContainerSize(gridW: Int, gridH: Int) {
        guard gridW > 0, gridH > 0 else { return }
        
        // Lấy kích thước màn hình hiện tại
        let canvasW = self.bounds.width > 0 ? self.bounds.width : 300
        let canvasH = self.bounds.height > 0 ? self.bounds.height : 300
        
        let gridRatio = CGFloat(gridW) / CGFloat(gridH)
        let canvasRatio = canvasW / canvasH
        
        var finalW: CGFloat
        var finalH: CGFloat
        
        // Tính toán kích thước hình vẽ sao cho Fit vào màn hình lúc đầu
        if gridRatio > canvasRatio {
            finalW = canvasW
            finalH = canvasW / gridRatio
        } else {
            finalH = canvasH
            finalW = canvasH * gridRatio
        }
        
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size
        
        // [PADDING] Thêm khoảng trống lớn xung quanh (bằng 50% màn hình)
        let paddingX = canvasW * 0.5
        let paddingY = canvasH * 0.5
        scrollView.contentInset = UIEdgeInsets(top: paddingY, left: paddingX, bottom: paddingY, right: paddingX)
        
        // Căn giữa lúc mới vào
        centerContent()
    }
    
    // Hàm căn giữa nội dung (Đã điều chỉnh để tôn trọng Inset)
    private func centerContent() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = containerView.frame
        
        // Chỉ căn giữa nếu hình NHỎ HƠN màn hình (lúc zoom out hết cỡ)
        // Nếu hình to hơn màn hình, để ScrollView tự lo việc cuộn
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        // Lưu ý: Không set lại frame liên tục khi đang zoom để tránh giật
        // containerView.frame = contentsFrame // (Dòng này iOS tự quản lý trong viewForZooming tốt hơn)
        
        // Logic căn giữa thủ công tốt nhất cho Inset lớn:
        let offsetX = max(0, (boundsSize.width - scrollView.contentSize.width) * 0.5)
        let offsetY = max(0, (boundsSize.height - scrollView.contentSize.height) * 0.5)
        
        // Đặt lại contentInset tạm thời để căn giữa hình nhỏ
        // (Đây là kỹ thuật nâng cao để hình luôn ở giữa khi zoom out, nhưng tự do khi zoom in)
        scrollView.contentInset.top = max((boundsSize.height - scrollView.contentSize.height) * 0.5, 0)
        if scrollView.contentInset.top < boundsSize.height * 0.5 {
             // Nếu hình to, trả lại padding lớn để di chuyển thoải mái
             let defaultPadding = boundsSize.height * 0.5
             scrollView.contentInset.top = defaultPadding
             scrollView.contentInset.bottom = defaultPadding
        }
        
        scrollView.contentInset.left = max((boundsSize.width - scrollView.contentSize.width) * 0.5, 0)
        if scrollView.contentInset.left < boundsSize.width * 0.5 {
             let defaultPadding = boundsSize.width * 0.5
             scrollView.contentInset.left = defaultPadding
             scrollView.contentInset.right = defaultPadding
        }
    }
    
    // ... (Giữ nguyên các hàm updatePixels, getPixelIndex, getGridPosition, getIndex, zoomToPixel) ...
    
    func updatePixels(at indices: [Int]) {
        guard let level = level else { return }
        let gridW = CGFloat(level.gridWidth)
        let viewW = containerView.bounds.width
        let viewH = containerView.bounds.height
        let pixelW = viewW / gridW
        let pixelH = viewH / CGFloat(level.gridHeight)
        for index in indices {
            let col = index % level.gridWidth
            let row = index / level.gridWidth
            let rect = CGRect(x: CGFloat(col) * pixelW, y: CGFloat(row) * pixelH, width: pixelW, height: pixelH).insetBy(dx: -0.5, dy: -0.5)
            drawingLayer.setNeedsDisplay(rect)
        }
    }
    
    func getPixelIndex(at locationInView: CGPoint) -> Int? {
        guard let level = level else { return nil }
        let locationInContainer = self.convert(locationInView, to: containerView)
        let pixelW = containerView.bounds.width / CGFloat(level.gridWidth)
        let pixelH = containerView.bounds.height / CGFloat(level.gridHeight)
        let col = Int(locationInContainer.x / pixelW)
        let row = Int(locationInContainer.y / pixelH)
        if col >= 0 && col < level.gridWidth && row >= 0 && row < level.gridHeight {
            return row * level.gridWidth + col
        }
        return nil
    }
    
    func getGridPosition(at locationInView: CGPoint) -> (col: Int, row: Int)? {
        guard let level = level else { return nil }
        let locationInContainer = self.convert(locationInView, to: containerView)
        let pixelW = containerView.bounds.width / CGFloat(level.gridWidth)
        let pixelH = containerView.bounds.height / CGFloat(level.gridHeight)
        if pixelW <= 0 || pixelH <= 0 { return nil }
        let col = Int(locationInContainer.x / pixelW)
        let row = Int(locationInContainer.y / pixelH)
        if col >= 0 && col < level.gridWidth && row >= 0 && row < level.gridHeight { return (col, row) }
        return nil
    }
    
    func getIndex(col: Int, row: Int) -> Int {
        guard let level = level else { return -1 }
        return row * level.gridWidth + col
    }
    
    func zoomToPixel(at index: Int) {
        guard let level = level, index < level.pixels.count else { return }
        let pixel = level.pixels[index]
        let targetScale: CGFloat = max(scrollView.zoomScale, 4.0)
        let zoomWidth = scrollView.bounds.width / targetScale
        let zoomHeight = scrollView.bounds.height / targetScale
        let contentW = containerView.bounds.width
        let contentH = containerView.bounds.height
        let pixelW = contentW / CGFloat(level.gridWidth)
        let pixelH = contentH / CGFloat(level.gridHeight)
        let pixelCenterX = (CGFloat(pixel.x) * pixelW) + (pixelW / 2)
        let pixelCenterY = (CGFloat(pixel.y) * pixelH) + (pixelH / 2)
        let zoomRect = CGRect(x: pixelCenterX - (zoomWidth / 2), y: pixelCenterY - (zoomHeight / 2), width: zoomWidth, height: zoomHeight)
        scrollView.zoom(to: zoomRect, animated: true)
    }
    
    // ScrollView Delegate (Cập nhật logic căn giữa khi zoom)
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return containerView }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent() // Gọi hàm căn giữa thông minh mới
        
        let currentZoom = scrollView.zoomScale
        var newStep = 0
        if currentZoom >= 8.5 { newStep = 3 }
        else if currentZoom >= 4.0 { newStep = 2 }
        else if currentZoom >= 1.2 { newStep = 1 }
        else { newStep = 0 }
        
        if newStep != lastZoomStep {
            lastZoomStep = newStep
            drawingLayer.updateZoom(currentZoom)
            drawingLayer.setNeedsDisplay()
        }
    }
    
    // MARK: - LỚP VẼ (Giữ nguyên logic vẽ mới nhất của bạn: Có lót trắng cho ô chưa tô)
    class NumberOverlayView: UIView {
        var level: LevelData?
        var currentNumber: Int = 0
        var currentZoom: CGFloat = 1.0
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear
            self.isUserInteractionEnabled = false
            self.contentMode = .redraw
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        func update(level: LevelData, currentNumber: Int, currentZoom: CGFloat) {
            self.level = level
            self.currentNumber = currentNumber
            self.currentZoom = currentZoom
        }
        
        func updateZoom(_ zoom: CGFloat) {
            self.currentZoom = zoom
        }
        
        override func draw(_ rect: CGRect) {
            guard let level = level, let context = UIGraphicsGetCurrentContext() else { return }
            
            let gridW = CGFloat(level.gridWidth)
            let gridH = CGFloat(level.gridHeight)
            if gridW == 0 || gridH == 0 { return }
            
            let totalW = self.bounds.width
            let totalH = self.bounds.height
            let pixelW = totalW / gridW
            let pixelH = totalH / gridH
            
            let shouldDrawNumber = currentZoom >= 1.2
            
            let startCol = Int(floor(rect.minX / pixelW))
            let endCol   = Int(ceil(rect.maxX / pixelW))
            let startRow = Int(floor(rect.minY / pixelH))
            let endRow   = Int(ceil(rect.maxY / pixelH))
            
            let minCol = max(0, startCol)
            let maxCol = min(level.gridWidth, endCol)
            let minRow = max(0, startRow)
            let maxRow = min(level.gridHeight, endRow)
            
            let fontSize = min(pixelW, pixelH) * 0.7
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font, .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            let activeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize), .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.black
            ]
            
            let gridColor = UIColor.systemGray.cgColor
            let lineWidth: CGFloat = 0.5 / currentZoom
            
            for r in minRow..<maxRow {
                for c in minCol..<maxCol {
                    
                    let index = r * level.gridWidth + c
                    if index >= level.pixels.count { continue }
                    let pixel = level.pixels[index]
                    
                    if pixel.number == 0 { continue } // Trong suốt -> Bỏ qua
                    
                    let x = CGFloat(c) * pixelW
                    let y = CGFloat(r) * pixelH
                    let pixelRect = CGRect(x: x, y: y, width: pixelW, height: pixelH)
                    
                    let colorIndex = pixel.number - 1
                    if colorIndex < 0 || colorIndex >= level.palette.count { continue }
                    let uiColor = level.palette[colorIndex]
                    
                    if currentNumber == -1 {
                        uiColor.setFill()
                        context.fill(pixelRect)
                    } else {
                        if pixel.isColored {
                            uiColor.setFill()
                            context.fill(pixelRect)
                            
                            context.setStrokeColor(uiColor.cgColor)
                            context.setLineWidth(lineWidth * 1.5)
                            context.stroke(pixelRect)
                        } else {
                            // Chưa tô -> Lót trắng trước
                            UIColor.white.setFill()
                            context.fill(pixelRect)
                            
                            context.setStrokeColor(gridColor)
                            context.setLineWidth(lineWidth)
                            context.stroke(pixelRect)
                            
                            if pixel.number == currentNumber {
                                UIColor.systemGray3.setFill()
                                context.fill(pixelRect)
                                uiColor.withAlphaComponent(0.5).setFill()
                                context.fill(pixelRect)
                                if shouldDrawNumber {
                                    drawNumber(pixel.number, at: pixelRect, fontHeight: font.lineHeight, attrs: activeAttributes)
                                }
                            } else {
                                uiColor.withAlphaComponent(0.2).setFill()
                                context.fill(pixelRect)
                                if shouldDrawNumber {
                                    drawNumber(pixel.number, at: pixelRect, fontHeight: font.lineHeight, attrs: textAttributes)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private func drawNumber(_ number: Int, at rect: CGRect, fontHeight: CGFloat, attrs: [NSAttributedString.Key: Any]) {
            let numberString = "\(number)" as NSString
            let textRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.height - fontHeight) / 2,
                width: rect.width,
                height: rect.height
            )
            numberString.draw(in: textRect, withAttributes: attrs)
        }
    }
}
