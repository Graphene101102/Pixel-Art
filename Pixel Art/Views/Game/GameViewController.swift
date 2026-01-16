import UIKit
import Combine

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // 1. UI Elements
    private let canvasView = CanvasView()
    private var paletteCollectionView: UICollectionView!
    private var magicButton: UIBarButtonItem!
    private var searchButton: UIBarButtonItem!
    private var musicButton: UIBarButtonItem!
    
    private let viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    private var lastDragPosition: (col: Int, row: Int)?
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures() // Chỉ còn Tap
        setupNavigationItems()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.isMusicOn.value { SoundManager.shared.playBackgroundMusic() }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent || self.isBeingDismissed { SoundManager.shared.stopBackgroundMusic() }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - SetupUI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = viewModel.levelSubject.value.name
        
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.scrollDirection = .horizontal
        paletteCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        paletteCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        paletteCollectionView.dataSource = self
        paletteCollectionView.delegate = self
        paletteCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paletteCollectionView)
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: paletteCollectionView.topAnchor, constant: -20),
            
            paletteCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paletteCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paletteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            paletteCollectionView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        // 1. Logic Vẽ Canvas (Chỉ cần nghe level)
        viewModel.levelSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.canvasView.render(level: level, currentNumber: self.viewModel.currentNumber)
                self.paletteCollectionView.reloadData()
            }
            .store(in: &cancellables)
            
        // 2. Logic Cập nhật Pixel (Vẽ đè 1 ô)
        viewModel.changesSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indices in
                self?.canvasView.updatePixels(at: indices)
                self?.paletteCollectionView.reloadData()
            }
            .store(in: &cancellables)
            
        // 3. Logic Chọn màu
        viewModel.selectedColorIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.paletteCollectionView.reloadData()
                self.canvasView.render(level: self.viewModel.levelSubject.value, currentNumber: self.viewModel.currentNumber)
            }
            .store(in: &cancellables)
            
        // 4. Các logic khác (Win, Magic, Music)
        viewModel.isComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let vc = LevelCompletedViewController(level: self.viewModel.levelSubject.value)
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true)
            }
            .store(in: &cancellables)
            
        viewModel.isMagicWandMode.sink { [weak self] isActive in
            (self?.magicButton.customView as? UIButton)?.tintColor = isActive ? .systemOrange : .systemBlue
        }.store(in: &cancellables)
        
        viewModel.isMusicOn.sink { [weak self] isOn in
            let iconName = isOn ? "speaker.wave.3.fill" : "speaker.slash.fill"
            (self?.musicButton.customView as? UIButton)?.setImage(UIImage(systemName: iconName), for: .normal)
        }.store(in: &cancellables)
    }
    
    // MARK: - GESTURES
    @objc func handleTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: canvasView)
        // CanvasView tự tính index dựa trên ScrollView
        if let pixelIndex = canvasView.getPixelIndex(at: location) {
            viewModel.handleTap(atIndex: pixelIndex)
        }
    }
    
    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        let location = g.location(in: canvasView)
        
        guard let gridPos = canvasView.getGridPosition(at: location) else { return }
        
        switch g.state {
        case .began:
            // Bắt đầu kéo: Tô ô hiện tại và lưu vị trí
            lastDragPosition = gridPos
            
            let currentIndex = canvasView.getIndex(col: gridPos.col, row: gridPos.row)
            viewModel.attemptToColor(indices: [currentIndex])
            
        case .changed:
            guard let lastPos = lastDragPosition else {
                lastDragPosition = gridPos
                return
            }
            
            // [THUẬT TOÁN BRESENHAM]
            // Tính toán tất cả các ô nằm giữa điểm cũ (lastPos) và điểm mới (gridPos)
            let points = getPointsOnLine(x0: lastPos.col, y0: lastPos.row, x1: gridPos.col, y1: gridPos.row)
            
            // Chuyển đổi các điểm (col, row) thành index
            let indices = points.compactMap { canvasView.getIndex(col: $0.col, row: $0.row) }
            
            // Gửi toàn bộ danh sách xuống ViewModel để tô 1 lần (Batch Update)
            if !indices.isEmpty {
                viewModel.attemptToColor(indices: indices)
            }
            
            // Cập nhật vị trí cũ
            lastDragPosition = gridPos
            
        case .ended, .cancelled:
            lastDragPosition = nil
            
        default:
            break
        }
    }
    
        // [THUẬT TOÁN NỐI ĐIỂM] Bresenham's Line Algorithm
        private func getPointsOnLine(x0: Int, y0: Int, x1: Int, y1: Int) -> [(col: Int, row: Int)] {
            var points: [(Int, Int)] = []
            
            var x = x0
            var y = y0
            
            let dx = abs(x1 - x)
            let dy = abs(y1 - y)
            
            let sx = x0 < x1 ? 1 : -1
            let sy = y0 < y1 ? 1 : -1
            
            var err = dx - dy
            
            while true {
                points.append((x, y))
                
                if x == x1 && y == y1 { break }
                
                let e2 = 2 * err
                
                let willMoveX = e2 > -dy
                let willMoveY = e2 < dx
                
                if willMoveX {
                    err -= dy
                    x += sx
                }
                if willMoveY {
                    err += dx
                    y += sy
                }
                
                if willMoveX && willMoveY {
                    points.append((x - sx, y))
                }
            }
            
            return points
        }
    
    private func setupGestures() {
        // Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasView.addGestureRecognizer(tap)
        
        // Pan (Kéo để tô)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        canvasView.addGestureRecognizer(pan)
        
        // [QUAN TRỌNG] Gán delegate để chặn/nhả cử chỉ thông minh
        pan.delegate = self
        
        canvasView.scrollViewPanGesture.require(toFail: pan)
    }
    
    // MARK: - ACTIONS
    @objc private func didTapMagicWand() { viewModel.triggerSmartMagic(); animateButton(magicButton) }
    @objc private func didTapMusic() { viewModel.toggleMusic(); animateButton(musicButton) }
    
    @objc private func didTapSearch() {
        animateButton(searchButton)
        if let targetIndex = viewModel.findUncoloredPixelIndex() {
            // CanvasView tự zoom vào ô index đó
            canvasView.zoomToPixel(at: targetIndex)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
    
    @objc private func didTapBack() {
        SoundManager.shared.stopBackgroundMusic()
        if let customView = navigationItem.leftBarButtonItem?.customView { animateView(customView) }
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else { dismiss(animated: true, completion: nil) }
    }
    
    // MARK: - SETUP NAVBAR (Giữ nguyên logic của bạn)
    private func setupNavigationItems() {
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBtn.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        backBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        backBtn.contentHorizontalAlignment = .center
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        
        func createBarButton(iconName: String, action: Selector) -> UIBarButtonItem {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: iconName), for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 40).isActive = true
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            return UIBarButtonItem(customView: button)
        }
        
        magicButton = createBarButton(iconName: "wand.and.stars", action: #selector(didTapMagicWand))
        searchButton = createBarButton(iconName: "magnifyingglass", action: #selector(didTapSearch))
        musicButton = createBarButton(iconName: viewModel.isMusicOn.value ? "speaker.wave.3.fill" : "speaker.slash.fill", action: #selector(didTapMusic))
        navigationItem.rightBarButtonItems = [magicButton, musicButton, searchButton]
    }
    
    private func animateView(_ view: UIView) {
        UIView.animate(withDuration: 0.1, animations: { view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) }) { _ in
            UIView.animate(withDuration: 0.1) { view.transform = .identity }
        }
    }
    private func animateButton(_ item: UIBarButtonItem) { if let v = item.customView { animateView(v) } }
}

extension GameViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.levelSubject.value.palette.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
        let level = viewModel.levelSubject.value
        let number = indexPath.item + 1
        let isCompleted = !level.pixels.contains { $0.number == number && !$0.isColored }
        cell.configure(color: level.palette[indexPath.item], number: number, isSelected: indexPath.item == viewModel.selectedColorIndex.value, isCompleted: isCompleted)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedColorIndex.send(indexPath.item)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let location = panGesture.location(in: canvasView)
                
                if let index = canvasView.getPixelIndex(at: location) {
                    if viewModel.canStartPainting(at: index) {
                        return true
                    }
                }
                return false
            }
            
            return true
        }
}
