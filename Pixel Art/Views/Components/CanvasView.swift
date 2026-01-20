import UIKit

// MARK: - CANVAS VIEW
class CanvasView: UIView, UIScrollViewDelegate {
    
    // 1. SCROLL VIEW
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        // Cấu hình Zoom cơ bản
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 5.0
        sv.bouncesZoom = true
        
        // Ẩn thanh cuộn để nhìn cho đẹp
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        
        // Cho phép nảy (rubber banding)
        sv.alwaysBounceHorizontal = true
        sv.alwaysBounceVertical = true
        
        // Tắt tự động chỉnh inset (quan trọng để tự căn giữa)
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
    
    // Biến cờ: True = Chế độ kết quả (Xem ảnh), False = Chế độ chơi (Vẽ)
    private var isResultMode: Bool = false
    
    // Expose Gesture cho GameViewController xử lý xung đột
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Khi view thay đổi kích thước (lần đầu hiện lên), nếu chưa zoom thì fit ảnh vào giữa
        if isResultMode && scrollView.zoomScale == 1.0 {
            if let lvl = level {
                setupForResultMode(level: lvl)
            }
        }
        // Luôn gọi căn giữa để đảm bảo vị trí đúng
        centerContent()
    }
    
    // MARK: - RENDER
    func render(level: LevelData, currentNumber: Int, redraw: Bool = true) {
        let levelChanged = self.level?.id != level.id
        self.level = level
        
        // Nếu currentNumber == -2 -> Chế độ Kết quả (Preview)
        if currentNumber == -2 {
            isResultMode = true
            setupForResultMode(level: level)
        } else {
            isResultMode = false
            // Chế độ chơi game: Chỉ reset layout khi đổi level
            if levelChanged {
                updateContainerSizeForGame(gridW: level.gridWidth, gridH: level.gridHeight)
                resetView()
                lastZoomStep = 0
            }
        }
        
        // Giảm scale vẽ ở mode kết quả để mượt hơn, mode game cần nét hơn
        drawingLayer.contentScaleFactor = isResultMode ? 4.0 : 7.0
        drawingLayer.update(level: level, currentNumber: currentNumber, currentZoom: scrollView.zoomScale)
        
        if redraw {
            drawingLayer.setNeedsDisplay()
        }
    }
    
    func resetView() {
        scrollView.setZoomScale(1.0, animated: true)
    }
    
    // --- [LOGIC 1] SETUP CHO MÀN KẾT QUẢ (-2) ---
    // Mục tiêu: Pan/Zoom mượt mà nhưng giới hạn trong khung ảnh (Photo Viewer Style)
    private func setupForResultMode(level: LevelData) {
        let gridW = CGFloat(level.gridWidth)
        let gridH = CGFloat(level.gridHeight)
        if gridW == 0 || gridH == 0 { return }
        
        // Lấy kích thước khung nhìn hiện tại
        let viewW = self.bounds.width > 0 ? self.bounds.width : 300
        let viewH = self.bounds.height > 0 ? self.bounds.height : 300
        
        let gridRatio = gridW / gridH
        let viewRatio = viewW / viewH
        
        var finalW: CGFloat
        var finalH: CGFloat
        
        // Tính toán kích thước ảnh sao cho vừa khít (Aspect Fit)
        if gridRatio > viewRatio {
            finalW = viewW
            finalH = viewW / gridRatio
        } else {
            finalH = viewH
            finalW = viewH * gridRatio
        }
        
        // 1. Đặt kích thước nội dung bằng đúng kích thước ảnh hiển thị
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size
        
        // 2. Xóa Padding ảo (để giới hạn vùng kéo)
        scrollView.contentInset = .zero
        
        // 3. Cấu hình Zoom
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        
        // 4. Bật Scroll
        scrollView.isScrollEnabled = true
        
        // 5. Căn giữa
        centerContent()
    }
    
    // --- [LOGIC 2] SETUP CHO GAME MODE ---
    // Mục tiêu: Padding cực lớn để kéo hình đi khắp nơi (Game Style)
    private func updateContainerSizeForGame(gridW: Int, gridH: Int) {
        guard gridW > 0, gridH > 0 else { return }
        let canvasW = self.bounds.width > 0 ? self.bounds.width : 300
        let canvasH = self.bounds.height > 0 ? self.bounds.height : 300
        let gridRatio = CGFloat(gridW) / CGFloat(gridH)
        let canvasRatio = canvasW / canvasH
        var finalW: CGFloat; var finalH: CGFloat
        if gridRatio > canvasRatio { finalW = canvasW; finalH = canvasW / gridRatio }
        else { finalH = canvasH; finalW = canvasH * gridRatio }
        
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size
        
        let paddingX = canvasW * 0.5
        let paddingY = canvasH * 0.5
        scrollView.contentInset = UIEdgeInsets(top: paddingY, left: paddingX, bottom: paddingY, right: paddingX)
        
        // Tự động đưa về giữa màn hình bằng offset (Logic câu trước)
        let targetOffsetX = (finalW - canvasW) / 2.0
        let targetOffsetY = (finalH - canvasH) / 2.0
        scrollView.contentOffset = CGPoint(x: targetOffsetX, y: targetOffsetY)
    }
    
    // MARK: - CENTER CONTENT (Logic Căn Giữa)
    private func centerContent() {
        if isResultMode {
            // [RESULT MODE]
            // Dùng kỹ thuật thay đổi 'center' của containerView
            // Đây là cách chuẩn để zoom ảnh mà vẫn giữ ảnh ở giữa khi zoom out
            let boundsSize = scrollView.bounds.size
            var frameToCenter = containerView.frame
            
            var offsetX: CGFloat = 0
            var offsetY: CGFloat = 0
            
            // Nếu ảnh nhỏ hơn màn hình -> Tính offset để đẩy vào giữa
            if frameToCenter.size.width < boundsSize.width {
                offsetX = (boundsSize.width - frameToCenter.size.width) / 2.0
            }
            if frameToCenter.size.height < boundsSize.height {
                offsetY = (boundsSize.height - frameToCenter.size.height) / 2.0
            }
            
            // Set tâm mới
            containerView.center = CGPoint(
                x: scrollView.contentSize.width / 2.0 + offsetX,
                y: scrollView.contentSize.height / 2.0 + offsetY
            )
            
        } else {
            // [GAME MODE] Giữ nguyên logic cũ dùng Inset
            let boundsSize = scrollView.bounds.size
            scrollView.contentInset.top = max((boundsSize.height - scrollView.contentSize.height) * 0.5, 0)
            if scrollView.contentInset.top < boundsSize.height * 0.5 {
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
    }
    
    // MARK: - SCROLL VIEW DELEGATE
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent() // Căn giữa liên tục khi đang zoom
        
        // Tối ưu việc vẽ lại khi zoom (chỉ vẽ lại ở các mốc zoom nhất định)
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
    
    // ... (Giữ nguyên các hàm Helper: updatePixels, getPixelIndex, zoomToPixel...) ...
    // Bạn copy lại các hàm helper này từ code cũ nhé
    func updatePixels(at indices: [Int], with newLevelData: LevelData) {
        // 1. Cập nhật dữ liệu mới nhất cho Canvas và lớp vẽ
        self.level = newLevelData
        drawingLayer.level = newLevelData
        
        // 2. Tính toán và vẽ lại các ô bị thay đổi
        let gridW = CGFloat(newLevelData.gridWidth)
        let viewW = containerView.bounds.width
        let viewH = containerView.bounds.height
        
        // Tránh chia cho 0
        if gridW == 0 { return }
        
        let pixelW = viewW / gridW
        let pixelH = viewH / CGFloat(newLevelData.gridHeight)
        
        for index in indices {
            let col = index % newLevelData.gridWidth
            let row = index / newLevelData.gridWidth
            
            // Tính toán khung hình chữ nhật của ô cần vẽ lại
            let rect = CGRect(
                x: CGFloat(col) * pixelW,
                y: CGFloat(row) * pixelH,
                width: pixelW,
                height: pixelH
            ).insetBy(dx: -0.5, dy: -0.5) // Mở rộng biên xíu để tránh viền trắng
            
            // Chỉ yêu cầu vẽ lại đúng vùng này
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
    
    // Class NumberOverlayView
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
            
            let activeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize), .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.black
            ]
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font, .paragraphStyle: paragraphStyle, .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            
            let gridColor = UIColor.systemGray.cgColor
            let lineWidth: CGFloat = 0.5 / currentZoom
            
            for r in minRow..<maxRow {
                for c in minCol..<maxCol {
                    let index = r * level.gridWidth + c
                    if index >= level.pixels.count { continue }
                    let pixel = level.pixels[index]
                    if pixel.number == 0 { continue }
                    
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
                            if currentNumber != -2 {
                                context.setStrokeColor(uiColor.cgColor)
                                context.setLineWidth(lineWidth * 1.5)
                                context.stroke(pixelRect)
                            }
                        } else {
                            if currentNumber == -2 { continue }
                            
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
                                uiColor.withAlphaComponent(0.15).setFill()
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
