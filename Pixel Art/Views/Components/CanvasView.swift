import UIKit

// MARK: - CANVAS VIEW (SCROLLABLE & ZOOMABLE)
class CanvasView: UIView, UIScrollViewDelegate {
    
    // 1. SCROLL VIEW
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 20.0
        sv.bouncesZoom = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.backgroundColor = .clear
        return sv
    }()
    
    // 2. CONTAINER & DRAWING LAYER
    private let containerView = UIView()
    private let drawingLayer = NumberOverlayView()
    private var level: LevelData?
    
    var scrollViewPanGesture: UIPanGestureRecognizer {
        return scrollView.panGestureRecognizer
    }
    
    // Callbacks (nếu cần sau này)
    var onZoomChange: ((CGFloat) -> Void)?
    
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
    
    // MARK: - RENDER (ĐÃ XÓA SCALE/OFFSET DƯ THỪA)
    func render(level: LevelData, currentNumber: Int, redraw: Bool = true) {
        let levelChanged = self.level?.id != level.id
        self.level = level
        
        if levelChanged {
            // Tự động tính toán kích thước container cho vừa khung
            updateContainerSize(gridW: level.gridWidth, gridH: level.gridHeight)
            scrollView.zoomScale = 1.0
        }
        
        drawingLayer.update(level: level, currentNumber: currentNumber)
        
        if redraw {
            drawingLayer.setNeedsDisplay()
        }
    }
    
    private func updateContainerSize(gridW: Int, gridH: Int) {
        guard gridW > 0, gridH > 0 else { return }
        
        // Lấy kích thước hiện tại của View
        let canvasW = self.bounds.width > 0 ? self.bounds.width : 300
        let canvasH = self.bounds.height > 0 ? self.bounds.height : 300
        
        let gridRatio = CGFloat(gridW) / CGFloat(gridH)
        let canvasRatio = canvasW / canvasH
        
        var finalW: CGFloat
        var finalH: CGFloat
        
        if gridRatio > canvasRatio {
            finalW = canvasW
            finalH = canvasW / gridRatio
        } else {
            finalH = canvasH
            finalW = canvasH * gridRatio
        }
        
        containerView.frame = CGRect(x: 0, y: 0, width: finalW, height: finalH)
        scrollView.contentSize = containerView.frame.size
        centerContent()
    }
    
    private func centerContent() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = containerView.frame
        
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
        
        containerView.frame = contentsFrame
    }
    
    // API Cập nhật Pixel
    func updatePixels(at indices: [Int]) {
        guard let level = level else { return }
        
        let gridW = CGFloat(level.gridWidth)
        // Lấy kích thước hiện tại của Container
        let viewW = containerView.bounds.width
        let viewH = containerView.bounds.height
        
        // Tính kích thước 1 ô pixel
        let pixelW = viewW / gridW
        let pixelH = viewH / CGFloat(level.gridHeight)
        
        for index in indices {
            // Tính toạ độ của ô pixel đó
            let col = index % level.gridWidth
            let row = index / level.gridWidth
            
            let rect = CGRect(
                x: CGFloat(col) * pixelW,
                y: CGFloat(row) * pixelH,
                width: pixelW,
                height: pixelH
            )
            // Hệ thống sẽ chỉ gọi hàm draw() cho đúng vùng này.
            drawingLayer.setNeedsDisplay(rect)
        }
    }
    
    // API Hỗ trợ Tap
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
    
    // API Zoom (Search)
    func zoomToPixel(at index: Int) {
        guard let level = level, index < level.pixels.count else { return }
        
        let pixel = level.pixels[index]
        
        // 1. Xác định mức Zoom mục tiêu
        // Nếu đang Zoom nhỏ hơn 3x -> Zoom lên 3x
        // Nếu đang Zoom lớn hơn 3x (ví dụ 10x) -> Giữ nguyên mức Zoom hiện tại
        let targetScale: CGFloat = max(scrollView.zoomScale, 4.0)
        
        // 2. Tính kích thước khung nhìn (Viewport) cần thiết để đạt được targetScale
        // Công thức: Kích thước Rect = Kích thước Màn hình / Scale mục tiêu
        let zoomWidth = scrollView.bounds.width / targetScale
        let zoomHeight = scrollView.bounds.height / targetScale
        
        // 3. Tính toạ độ tâm của Pixel mục tiêu (trên ContainerView)
        let contentW = containerView.bounds.width
        let contentH = containerView.bounds.height
        
        let pixelW = contentW / CGFloat(level.gridWidth)
        let pixelH = contentH / CGFloat(level.gridHeight)
        
        // Toạ độ tâm của ô pixel
        let pixelCenterX = (CGFloat(pixel.x) * pixelW) + (pixelW / 2)
        let pixelCenterY = (CGFloat(pixel.y) * pixelH) + (pixelH / 2)
        
        // 4. Tạo Rect có tâm nằm đúng tại ô Pixel đó
        let zoomRect = CGRect(
            x: pixelCenterX - (zoomWidth / 2),
            y: pixelCenterY - (zoomHeight / 2),
            width: zoomWidth,
            height: zoomHeight
        )
        
        // 5. Thực hiện Zoom mượt mà
        scrollView.zoom(to: zoomRect, animated: true)
    }
    
    // ScrollView Delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return containerView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerContent() }
    
    // MARK: - Lớp vẽ
    class NumberOverlayView: UIView {
        
        var level: LevelData?
        var currentNumber: Int = 0
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .clear
            self.isUserInteractionEnabled = false
            self.contentMode = .redraw // Vẽ lại khi bounds thay đổi
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        func update(level: LevelData, currentNumber: Int) {
            self.level = level
            self.currentNumber = currentNumber
            self.setNeedsDisplay()
        }
        
        override func draw(_ rect: CGRect) {
            guard let level = level, let context = UIGraphicsGetCurrentContext() else { return }
            
            let gridW = CGFloat(level.gridWidth)
            let gridH = CGFloat(level.gridHeight)
            
            if gridW == 0 || gridH == 0 { return }
            
            // Tính kích thước 1 pixel dựa trên kích thước thực tế của View
            let totalW = self.bounds.width
            let totalH = self.bounds.height
            
            let pixelW = totalW / gridW
            let pixelH = totalH / gridH
            
            // Chỉ lặp qua các cột (col) và hàng (row) nằm trong vùng 'rect'
            let startCol = Int(floor(rect.minX / pixelW))
            let endCol   = Int(ceil(rect.maxX / pixelW))
            
            let startRow = Int(floor(rect.minY / pixelH))
            let endRow   = Int(ceil(rect.maxY / pixelH))
            
            // Giới hạn chỉ số để không bị crash
            let minCol = max(0, startCol)
            let maxCol = min(level.gridWidth, endCol)
            
            let minRow = max(0, startRow)
            let maxRow = min(level.gridHeight, endRow)
            
            // Cấu hình Font chữ
            let fontSize = min(pixelW, pixelH) * 0.7
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black.withAlphaComponent(0.6)
            ]
            
            for r in minRow..<maxRow {
                for c in minCol..<maxCol {
                    
                    let index = r * level.gridWidth + c
                    
                    // Kiểm tra index an toàn
                    if index >= level.pixels.count { continue }
                    
                    let pixel = level.pixels[index]
                    
                    // Tính khung hình chữ nhật cho pixel này
                    let x = CGFloat(c) * pixelW
                    let y = CGFloat(r) * pixelH
                    let pixelRect = CGRect(x: x, y: y, width: pixelW, height: pixelH)
                    
                    // Lấy màu từ Palette (An toàn)
                    let colorIndex = pixel.number - 1
                    if colorIndex < 0 || colorIndex >= level.palette.count { continue }
                    let uiColor = level.palette[colorIndex]
                    
                    // --- LOGIC VẼ ---
                    
                    if currentNumber == -1 {
                        // 1. PREVIEW: Full màu
                        uiColor.setFill()
                        context.fill(pixelRect)
                        
                    } else {
                        // 2. IN-GAME
                        if pixel.isColored {
                            // Đã tô: Full màu
                            uiColor.setFill()
                            context.fill(pixelRect)
                        } else {
                            // Chưa tô
                            if pixel.number == currentNumber {
                                // Số đang chọn: Mờ 50% + Số đậm
                                uiColor.withAlphaComponent(1.0).setFill()
                                context.fill(pixelRect)
                                
                                let activeAttributes: [NSAttributedString.Key: Any] = [
                                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                                    .paragraphStyle: paragraphStyle,
                                    .foregroundColor: UIColor.black.withAlphaComponent(0.8)
                                ]
                                drawNumber(pixel.number, at: pixelRect, fontHeight: font.lineHeight, attrs: activeAttributes)
                                
                            } else {
                                // Số khác: Mờ 20% + Số nhạt
                                uiColor.withAlphaComponent(0.2).setFill()
                                context.fill(pixelRect)
                                drawNumber(pixel.number, at: pixelRect, fontHeight: font.lineHeight, attrs: textAttributes)
                            }
                        }
                    }
                }
            }
        }
        
        // Hàm phụ trợ để vẽ số căn giữa
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
    
    //Hàm lấy Col/Row từ toạ độ màn hình (Dùng cho Bresenham)
    func getGridPosition(at locationInView: CGPoint) -> (col: Int, row: Int)? {
        guard let level = level else { return nil }
        
        let locationInContainer = self.convert(locationInView, to: containerView)
        let pixelW = containerView.bounds.width / CGFloat(level.gridWidth)
        let pixelH = containerView.bounds.height / CGFloat(level.gridHeight)
        
        // Tránh chia cho 0
        if pixelW <= 0 || pixelH <= 0 { return nil }
        
        let col = Int(locationInContainer.x / pixelW)
        let row = Int(locationInContainer.y / pixelH)
        
        if col >= 0 && col < level.gridWidth && row >= 0 && row < level.gridHeight {
            return (col, row)
        }
        return nil
    }
    
    //Hàm chuyển đổi Col/Row thành Index mảng (Để ViewModel dùng)
    func getIndex(col: Int, row: Int) -> Int {
        guard let level = level else { return -1 }
        return row * level.gridWidth + col
    }
}
