import UIKit

// MARK: - CANVAS VIEW (FINAL VISUAL TWEAKS & NEW ANIMATION)
class CanvasView: UIView, UIScrollViewDelegate {
    
    // 1. SCROLL VIEW
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 5.0 // Max zoom level
        sv.bouncesZoom = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        sv.alwaysBounceHorizontal = true
        sv.alwaysBounceVertical = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    private let containerView: UIView = {
        let v = UIView(); v.backgroundColor = .clear; return v
    }()
    
    // LAYER 1: Lưới + Số + Nền Hint (Nằm dưới)
    private let gridLayer = GridNumberView()
    // LAYER 2: Màu đã tô (Nằm đè lên trên)
    private let colorLayer = ColoringView()
    
    private var level: LevelData?
    private var lastZoomStep: Int = 0
    private var isResultMode: Bool = false
    
    // Animation Pool
    private var animationViewPool: [UIView] = []
    
    var scrollViewPanGesture: UIPanGestureRecognizer {
        return scrollView.panGestureRecognizer
    }
    
    override init(frame: CGRect) { super.init(frame: frame); setupUI() }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        self.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        scrollView.addSubview(containerView)
        
        // Add Layers
        gridLayer.translatesAutoresizingMaskIntoConstraints = false
        gridLayer.backgroundColor = .clear
        gridLayer.layer.drawsAsynchronously = true
        containerView.addSubview(gridLayer)
        
        colorLayer.translatesAutoresizingMaskIntoConstraints = false
        colorLayer.backgroundColor = .clear
        containerView.addSubview(colorLayer)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            gridLayer.topAnchor.constraint(equalTo: containerView.topAnchor),
            gridLayer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            gridLayer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gridLayer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            colorLayer.topAnchor.constraint(equalTo: containerView.topAnchor),
            colorLayer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            colorLayer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            colorLayer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Init Pool
        for _ in 0..<30 {
            let v = UIView()
            v.isUserInteractionEnabled = false
            // [Change] clipsToBounds = false để vẽ shadow (glow) ra ngoài
            v.clipsToBounds = false
            animationViewPool.append(v)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isResultMode && scrollView.zoomScale == 1.0, let lvl = level {
            setupForResultMode(level: lvl)
        }
        centerContent()
    }
    
    // MARK: - RENDER LOGIC
    func render(level: LevelData, currentNumber: Int, redraw: Bool = true) {
        let levelChanged = self.level?.id != level.id
        self.level = level
        
        gridLayer.level = level
        gridLayer.currentNumber = currentNumber
        colorLayer.level = level
        
        if currentNumber == -2 {
            isResultMode = true
            setupForResultMode(level: level)
            gridLayer.isHidden = true
        } else {
            isResultMode = false
            gridLayer.isHidden = false
            if levelChanged {
                updateContainerSizeForGame(gridW: level.gridWidth, gridH: level.gridHeight)
                resetView()
                lastZoomStep = 0
            }
        }
        
        // Luôn vẽ với độ phân giải Max Zoom
        let scale = scrollView.maximumZoomScale
        gridLayer.contentScaleFactor = scale
        colorLayer.contentScaleFactor = scale
        
        
        if redraw {
            gridLayer.setNeedsDisplay()
            colorLayer.setNeedsDisplay()
        }
    }
    
    func resetView() {
        let targetScale = scrollView.minimumZoomScale > 0 ? scrollView.minimumZoomScale : 1.0
        scrollView.setZoomScale(targetScale, animated: true)
    }
    
    // --- BATCH PAINTING WITH NEW ANIMATION ---
    func batchPaintPixels(at indices: [Int], color: UIColor) {
        guard let currentLevel = level, !indices.isEmpty else { return }
        
        let gridW = CGFloat(currentLevel.gridWidth)
        let pixelW = containerView.bounds.width / gridW
        let pixelH = containerView.bounds.height / CGFloat(currentLevel.gridHeight)
        
        var unionRect: CGRect?
        var animationCount = 0
        let maxAnimations = 15
        
        for index in indices {
            // 1. Data update
            colorLayer.tempPaintedIndices.insert(index)
            
            // Calculate positions
            let col = index % currentLevel.gridWidth
            let row = index / currentLevel.gridWidth
            
            let x0 = floor(CGFloat(col) * pixelW)
            let x1 = floor(CGFloat(col + 1) * pixelW)
            let y0 = floor(CGFloat(row) * pixelH)
            let y1 = floor(CGFloat(row + 1) * pixelH)
            let cellRect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
            
            // Union rect for redrawing layers
            if unionRect == nil { unionRect = cellRect }
            else { unionRect = unionRect?.union(cellRect) }
            
            // 2. [NEW ANIMATION] Dấu chấm sáng chính giữa
            if animationCount < maxAnimations {
                if let animView = animationViewPool.popLast() {
                    
                    // Kích thước chấm tròn (khoảng 50% ô)
                    let dotSize = min(cellRect.width, cellRect.height) * 0.5
                    let dotRect = CGRect(
                        x: cellRect.midX - dotSize / 2,
                        y: cellRect.midY - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    
                    // Cấu hình View
                    animView.frame = dotRect
                    animView.backgroundColor = .white // Tâm màu trắng sáng
                    animView.layer.cornerRadius = dotSize / 2
                    
                    // Viền sáng (màu của bút tô)
                    animView.layer.borderWidth = dotSize * 0.15 // Viền dày vừa phải
                    animView.layer.borderColor = color.withAlphaComponent(0.9).cgColor
                    
                    // Hiệu ứng phát sáng (Glow)
                    animView.layer.shadowColor = color.cgColor
                    animView.layer.shadowRadius = dotSize * 0.3
                    animView.layer.shadowOpacity = 0.6
                    animView.layer.shadowOffset = .zero
                    
                    // Trạng thái ban đầu (Nhỏ và trong suốt)
                    animView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                    animView.alpha = 0.0
                    containerView.addSubview(animView)
                    
                    // Chuỗi hiệu ứng: Hiện nhanh -> Mờ dần đi
                    UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut], animations: {
                        animView.transform = .identity // Phóng to về kích thước thật
                        animView.alpha = 1.0
                    }) { _ in
                        UIView.animate(withDuration: 0.25, delay: 0.05, options: [.curveEaseIn], animations: {
                            animView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) // Thu nhỏ lại
                            animView.alpha = 0.0 // Mờ dần
                        }) { [weak self] _ in
                            // Reset style trước khi trả về kho
                            animView.layer.shadowOpacity = 0
                            animView.layer.borderWidth = 0
                            animView.removeFromSuperview()
                            self?.animationViewPool.append(animView)
                        }
                    }
                    animationCount += 1
                }
            }
        }
        
        // 3. Redraw Layers
        if let rect = unionRect {
            colorLayer.setNeedsDisplay(rect)
            gridLayer.setNeedsDisplay(rect)
        }
    }
    
    func updatePixels(at indices: [Int], with newLevelData: LevelData) {
        self.level = newLevelData; colorLayer.level = newLevelData; gridLayer.level = newLevelData
        for index in indices { colorLayer.tempPaintedIndices.remove(index) }
        if indices.isEmpty { return }
        
        let gridW = CGFloat(newLevelData.gridWidth)
        let pixelW = containerView.bounds.width / gridW
        let pixelH = containerView.bounds.height / CGFloat(newLevelData.gridHeight)
        
        var unionRect: CGRect?
        for index in indices {
            let col = index % newLevelData.gridWidth; let row = index / newLevelData.gridWidth
            let x0 = floor(CGFloat(col) * pixelW); let x1 = floor(CGFloat(col + 1) * pixelW)
            let y0 = floor(CGFloat(row) * pixelH); let y1 = floor(CGFloat(row + 1) * pixelH)
            let rect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
            if unionRect == nil { unionRect = rect } else { unionRect = unionRect?.union(rect) }
        }
        
        if let rect = unionRect {
            colorLayer.setNeedsDisplay(rect)
            gridLayer.setNeedsDisplay(rect)
        }
    }
    
    // ... Helpers (Copy from previous)
    private func setupForResultMode(level: LevelData) {
        let gridW = CGFloat(level.gridWidth); let gridH = CGFloat(level.gridHeight)
        if gridW == 0 || gridH == 0 { return }
        let viewW = bounds.width > 0 ? bounds.width : 300; let viewH = bounds.height > 0 ? bounds.height : 300
        let gridRatio = gridW / gridH; let viewRatio = viewW / viewH
        var finalW: CGFloat; var finalH: CGFloat
        if gridRatio > viewRatio { finalW = viewW; finalH = viewW / gridRatio }
        else { finalH = viewH; finalW = viewH * gridRatio }
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size; scrollView.contentInset = .zero
        scrollView.minimumZoomScale = 1.0; scrollView.maximumZoomScale = 5.0; scrollView.zoomScale = 1.0; scrollView.isScrollEnabled = true
        centerContent()
    }
    private func updateContainerSizeForGame(gridW: Int, gridH: Int) {
        guard gridW > 0, gridH > 0 else { return }
        let canvasW = bounds.width > 0 ? bounds.width : 300; let canvasH = bounds.height > 0 ? bounds.height : 300
        let gridRatio = CGFloat(gridW) / CGFloat(gridH); let canvasRatio = canvasW / canvasH
        var finalW: CGFloat; var finalH: CGFloat
        if gridRatio > canvasRatio { finalW = canvasW; finalH = canvasW / gridRatio }
        else { finalH = canvasH; finalW = canvasH * gridRatio }
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size
        let paddingX = canvasW * 0.5; let paddingY = canvasH * 0.5
        scrollView.contentInset = UIEdgeInsets(top: paddingY, left: paddingX, bottom: paddingY, right: paddingX)
        let targetOffsetX = (finalW - canvasW) / 2.0; let targetOffsetY = (finalH - canvasH) / 2.0
        scrollView.contentOffset = CGPoint(x: targetOffsetX, y: targetOffsetY)
    }
    private func centerContent() {
        if isResultMode {
            let boundsSize = scrollView.bounds.size; let frameToCenter = containerView.frame
            var offsetX: CGFloat = 0; var offsetY: CGFloat = 0
            if frameToCenter.size.width < boundsSize.width { offsetX = (boundsSize.width - frameToCenter.size.width) / 2.0 }
            if frameToCenter.size.height < boundsSize.height { offsetY = (boundsSize.height - frameToCenter.size.height) / 2.0 }
            containerView.center = CGPoint(x: scrollView.contentSize.width / 2.0 + offsetX, y: scrollView.contentSize.height / 2.0 + offsetY)
        } else {
            let boundsSize = scrollView.bounds.size
            scrollView.contentInset.top = max((boundsSize.height - scrollView.contentSize.height) * 0.5, 0)
            if scrollView.contentInset.top < boundsSize.height * 0.5 { let def = boundsSize.height * 0.5; scrollView.contentInset.top = def; scrollView.contentInset.bottom = def }
            scrollView.contentInset.left = max((boundsSize.width - scrollView.contentSize.width) * 0.5, 0)
            if scrollView.contentInset.left < boundsSize.width * 0.5 { let def = boundsSize.width * 0.5; scrollView.contentInset.left = def; scrollView.contentInset.right = def }
        }
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return containerView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        
    }
    func getPixelIndex(at locationInView: CGPoint) -> Int? {
        guard let level = level else { return nil }
        let loc = convert(locationInView, to: containerView)
        let pixelW = containerView.bounds.width / CGFloat(level.gridWidth)
        let pixelH = containerView.bounds.height / CGFloat(level.gridHeight)
        if pixelW <= 0 || pixelH <= 0 { return nil }
        let col = Int(loc.x / pixelW); let row = Int(loc.y / pixelH)
        if col >= 0 && col < level.gridWidth && row >= 0 && row < level.gridHeight { return row * level.gridWidth + col }
        return nil
    }
    func getGridPosition(at locationInView: CGPoint) -> (col: Int, row: Int)? {
        guard let level = level else { return nil }
        let loc = convert(locationInView, to: containerView)
        let pixelW = containerView.bounds.width / CGFloat(level.gridWidth)
        let pixelH = containerView.bounds.height / CGFloat(level.gridHeight)
        if pixelW <= 0 || pixelH <= 0 { return nil }
        let col = Int(loc.x / pixelW); let row = Int(loc.y / pixelH)
        if col >= 0 && col < level.gridWidth && row >= 0 && row < level.gridHeight { return (col, row) }
        return nil
    }
    func getIndex(col: Int, row: Int) -> Int { guard let level = level else { return -1 }; return row * level.gridWidth + col }
    func zoomToPixel(at index: Int) {
        guard let level = level, index < level.pixels.count else { return }
        let pixel = level.pixels[index]
        let targetScale: CGFloat = max(scrollView.zoomScale, 4.0)
        let zoomWidth = scrollView.bounds.width / targetScale; let zoomHeight = scrollView.bounds.height / targetScale
        let contentW = containerView.bounds.width; let contentH = containerView.bounds.height
        let pixelW = contentW / CGFloat(level.gridWidth); let pixelH = contentH / CGFloat(level.gridHeight)
        let cx = (CGFloat(pixel.x) * pixelW) + (pixelW / 2); let cy = (CGFloat(pixel.y) * pixelH) + (pixelH / 2)
        scrollView.zoom(to: CGRect(x: cx - zoomWidth/2, y: cy - zoomHeight/2, width: zoomWidth, height: zoomHeight), animated: true)
    }
    
    // MARK: - VIEW LỚP 1: LƯỚI & SỐ & HINT (FIXED VISUALS)
    class GridNumberView: UIView {
        var level: LevelData?
        var currentNumber: Int = 0
        
        private var cachedAttributes: [NSAttributedString.Key: Any]?
        private var cachedActiveAttributes: [NSAttributedString.Key: Any]?
        private var lastFontSize: CGFloat = 0
        private var cachedFontLineHeight: CGFloat = 0
        
        override init(frame: CGRect) {
            super.init(frame: frame); self.backgroundColor = .clear; self.isUserInteractionEnabled = false; self.contentMode = .redraw
        }
        required init?(coder: NSCoder) { fatalError() }
        
        override func draw(_ rect: CGRect) {
            guard let level = level, let context = UIGraphicsGetCurrentContext() else { return }
            let gridW = CGFloat(level.gridWidth); let gridH = CGFloat(level.gridHeight)
            if gridW == 0 || gridH == 0 { return }
            
            let totalW = bounds.width; let totalH = bounds.height
            let pixelW = totalW / gridW; let pixelH = totalH / gridH
            let shouldDrawNumber = true
            
            let startCol = Int(floor(rect.minX / pixelW)); let endCol = Int(ceil(rect.maxX / pixelW))
            let startRow = Int(floor(rect.minY / pixelH)); let endRow = Int(ceil(rect.maxY / pixelH))
            let minCol = max(0, startCol); let maxCol = min(level.gridWidth, endCol)
            let minRow = max(0, startRow); let maxRow = min(level.gridHeight, endRow)
            
            // Cache Font - [Change 1: SỐ NHỎ LẠI]
            let fontSize = min(pixelW, pixelH) * 0.5 // Giảm từ 0.7 xuống 0.5
            if abs(fontSize - lastFontSize) > 0.5 || cachedAttributes == nil {
                lastFontSize = fontSize
                let font = UIFont.boldSystemFont(ofSize: fontSize)
                cachedFontLineHeight = font.lineHeight
                let style = NSMutableParagraphStyle(); style.alignment = .center
                cachedActiveAttributes = [.font: font, .paragraphStyle: style, .foregroundColor: UIColor.black]
                cachedAttributes = [.font: font, .paragraphStyle: style, .foregroundColor: UIColor.black.withAlphaComponent(0.6)]
            }
            
            context.setShouldAntialias(false)
            context.setLineWidth(0.3)
            
            // [Change 2: VIỀN MỜ LẠI]
            // Sử dụng systemGray5 (sáng hơn Gray4) để làm viền mờ hơn
            let gridColor = UIColor.systemGray5.withAlphaComponent(0.05).cgColor
            context.setStrokeColor(gridColor)
            
            for r in minRow..<maxRow {
                for c in minCol..<maxCol {
                    let index = r * level.gridWidth + c
                    if index >= level.pixels.count { continue }
                    let pixel = level.pixels[index]
                    
                    if pixel.number == 0 { continue }
                    if pixel.isColored { continue }
                    
                    // Exact Tiling
                    let x0 = floor(CGFloat(c) * pixelW)
                    let x1 = floor(CGFloat(c + 1) * pixelW)
                    let y0 = floor(CGFloat(r) * pixelH)
                    let y1 = floor(CGFloat(r + 1) * pixelH)
                    let pixelRect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
                    
                    // 1. LÓT NỀN TRẮNG
                    UIColor.white.setFill()
                    context.fill(pixelRect)
                    
                    // 2. MÀU GỢI Ý (HINT)
                    let colorIndex = pixel.number - 1
                    if colorIndex >= 0 && colorIndex < level.palette.count {
                        let uiColor = level.palette[colorIndex]
                        
                        // Alpha: 0.4 (Cùng số) | 0.1 (Khác số)
                        let alpha = (pixel.number == currentNumber) ? 0.6 : 0.3
                        
                        uiColor.withAlphaComponent(alpha).setFill()
                        context.fill(pixelRect)
                        
                        // Highlight bổ sung
                        if pixel.number == currentNumber {
                            UIColor.black.withAlphaComponent(0.05).setFill()
                            context.fill(pixelRect)
                        }
                    }
                    
                    // 3. VẼ LƯỚI
                    context.stroke(pixelRect)
                    
                    // 4. VẼ SỐ
                    if shouldDrawNumber {
                        let attrs = (pixel.number == currentNumber) ? cachedActiveAttributes : cachedAttributes
                        if let attributes = attrs {
                            drawNumber(pixel.number, at: pixelRect, fontHeight: cachedFontLineHeight, attrs: attributes)
                        }
                    }
                }
            }
        }
        
        @inline(__always)
        private func drawNumber(_ number: Int, at rect: CGRect, fontHeight: CGFloat, attrs: [NSAttributedString.Key: Any]) {
            let textRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.height - fontHeight) / 2, width: rect.width, height: rect.height)
            ("\(number)" as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
    
    // MARK: - VIEW LỚP 2: MÀU SẮC (ColoringView)
    class ColoringView: UIView {
        var level: LevelData?
        var tempPaintedIndices: Set<Int> = []
        
        override init(frame: CGRect) {
            super.init(frame: frame); self.backgroundColor = .clear; self.isUserInteractionEnabled = false; self.contentMode = .redraw
        }
        required init?(coder: NSCoder) { fatalError() }
        
        override func draw(_ rect: CGRect) {
            guard let level = level, let context = UIGraphicsGetCurrentContext() else { return }
            let gridW = CGFloat(level.gridWidth); let gridH = CGFloat(level.gridHeight)
            if gridW == 0 || gridH == 0 { return }
            
            let totalW = bounds.width; let totalH = bounds.height
            let pixelW = totalW / gridW; let pixelH = totalH / gridH
            
            let startCol = Int(floor(rect.minX / pixelW)); let endCol = Int(ceil(rect.maxX / pixelW))
            let startRow = Int(floor(rect.minY / pixelH)); let endRow = Int(ceil(rect.maxY / pixelH))
            let minCol = max(0, startCol); let maxCol = min(level.gridWidth, endCol)
            let minRow = max(0, startRow); let maxRow = min(level.gridHeight, endRow)
            
            context.setShouldAntialias(false)
            
            for r in minRow..<maxRow {
                for c in minCol..<maxCol {
                    let index = r * level.gridWidth + c
                    if index >= level.pixels.count { continue }
                    
                    let isColored = level.pixels[index].isColored || tempPaintedIndices.contains(index)
                    
                    if isColored {
                        let pixel = level.pixels[index]
                        let colorIndex = pixel.number - 1
                        
                        if colorIndex >= 0 && colorIndex < level.palette.count {
                            let uiColor = level.palette[colorIndex]
                            
                            // Exact Tiling
                            let x0 = floor(CGFloat(c) * pixelW)
                            let x1 = floor(CGFloat(c + 1) * pixelW)
                            let y0 = floor(CGFloat(r) * pixelH)
                            let y1 = floor(CGFloat(r + 1) * pixelH)
                            let pixelRect = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
                            
                            uiColor.setFill()
                            context.fill(pixelRect)
                        }
                    }
                }
            }
        }
    }
}
