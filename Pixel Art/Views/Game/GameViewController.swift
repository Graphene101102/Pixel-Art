import UIKit
import Combine

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    private let viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    private var lastDragPosition: (col: Int, row: Int)?
    
    // MARK: - UI Elements
    
    // 1. Background Image (Lớp dưới cùng)
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    // 2. Main Canvas (Full Screen - Lớp thứ 2)
    private let canvasView = CanvasView()
    
    // 3. Top Bar (Chứa Back, User, Check)
    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let userButton = UIButton(type: .system)
    private let checkButton = UIButton(type: .system)
    
    // 4. Music Button
    private let musicButton = UIButton(type: .system)
    
    // 5. Container màu trắng chứa Palette (Lớp đáy giao diện điều khiển)
    private let bottomPaletteContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        // Shadow nhẹ
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -3)
        v.layer.shadowRadius = 8
        return v
    }()
    
    // 6. Palette Collection View
    private var paletteCollectionView: UICollectionView!
    
    // 7. Tools Stack (Search, Magic, Fit)
    private let toolsStackView = UIStackView()
    private let searchButton = UIButton(type: .system)
    private let magicButton = UIButton(type: .system)
    private let fitButton = UIButton(type: .system)
    private let magicBadgeView = UIView()
    
    // MARK: - Init
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.isMusicOn.value { SoundManager.shared.playBackgroundMusic() }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent || self.isBeingDismissed { SoundManager.shared.pauseBackgroundMusic() }
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // --- Layer 1: Background & Canvas ---
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        // --- Layer 2: Top Bar ---
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBarView)
        
        configureSquareButton(backButton, icon: "arrow.left")
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        configureSquareButton(userButton, icon: "person.fill")
        
        configureSquareButton(checkButton, icon: "checkmark.circle.fill")
        // Gán action cho Check Button
        checkButton.addTarget(self, action: #selector(didTapCheck), for: .touchUpInside)
        
        [backButton, userButton, checkButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            topBarView.addSubview($0)
        }
        
        // --- Layer 3: Music Button ---
        configureSquareButton(musicButton, icon: "music.note")
        musicButton.translatesAutoresizingMaskIntoConstraints = false
        musicButton.addTarget(self, action: #selector(didTapMusic), for: .touchUpInside)
        view.addSubview(musicButton)
        
        // --- Layer 4: Bottom Palette Container (Dải trắng) ---
        bottomPaletteContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomPaletteContainer)
        
        // --- Layer 5: Palette CollectionView (Nằm TRONG dải trắng) ---
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        paletteCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        paletteCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        paletteCollectionView.dataSource = self
        paletteCollectionView.delegate = self
        paletteCollectionView.backgroundColor = .clear
        paletteCollectionView.showsHorizontalScrollIndicator = false
        paletteCollectionView.translatesAutoresizingMaskIntoConstraints = false
        bottomPaletteContainer.addSubview(paletteCollectionView)
        
        // --- Layer 6: Tools Stack (Nằm TRÊN dải trắng) ---
        toolsStackView.axis = .horizontal
        toolsStackView.distribution = .equalSpacing
        toolsStackView.alignment = .center
        toolsStackView.spacing = 16
        toolsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolsStackView)
        
        configureToolButton(searchButton, icon: "magnifyingglass")
        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        
        configureToolButton(magicButton, icon: "wand.and.stars")
        magicButton.addTarget(self, action: #selector(didTapMagicWand), for: .touchUpInside)
        
        magicBadgeView.backgroundColor = .red
        magicBadgeView.layer.cornerRadius = 6
        magicBadgeView.translatesAutoresizingMaskIntoConstraints = false
        magicBadgeView.isHidden = true
        magicButton.addSubview(magicBadgeView)
        
        configureToolButton(fitButton, icon: "arrow.up.left.and.arrow.down.right")
        // [QUAN TRỌNG] Gán action cho Fit Button
        fitButton.addTarget(self, action: #selector(didTapFit), for: .touchUpInside)
        
        [searchButton, magicButton, fitButton].forEach {
            toolsStackView.addArrangedSubview($0)
        }
        
        // --- CONSTRAINTS ---
        NSLayoutConstraint.activate([
            // 1. BG & Canvas (Full Screen)
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 2. Top Bar
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topBarView.heightAnchor.constraint(equalToConstant: 50),
            
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            userButton.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            userButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            checkButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),
            checkButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            // 3. Music Button
            musicButton.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 16),
            musicButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 4. Bottom Palette Container (Dải trắng)
            bottomPaletteContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaletteContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPaletteContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor), // Sát đáy
            // Chiều cao tự động theo nội dung bên trong
            
            // 5. Palette CV (Trong Container)
            paletteCollectionView.leadingAnchor.constraint(equalTo: bottomPaletteContainer.leadingAnchor),
            paletteCollectionView.trailingAnchor.constraint(equalTo: bottomPaletteContainer.trailingAnchor),
            paletteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            paletteCollectionView.heightAnchor.constraint(equalToConstant: 60),
            
            // Đỉnh container trắng cách đỉnh Palette 15pt
            bottomPaletteContainer.topAnchor.constraint(equalTo: paletteCollectionView.topAnchor, constant: -15),
            
            // 6. Tools Stack (Trên Container trắng)
            toolsStackView.bottomAnchor.constraint(equalTo: bottomPaletteContainer.topAnchor, constant: -20),
            toolsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toolsStackView.heightAnchor.constraint(equalToConstant: 50),
            
            // Magic Badge
            magicBadgeView.topAnchor.constraint(equalTo: magicButton.topAnchor, constant: 8),
            magicBadgeView.trailingAnchor.constraint(equalTo: magicButton.trailingAnchor, constant: -8),
            magicBadgeView.widthAnchor.constraint(equalToConstant: 8),
            magicBadgeView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    // --- Helper Functions ---
    private func configureSquareButton(_ btn: UIButton, icon: String) {
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func configureToolButton(_ btn: UIButton, icon: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        
        btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 3)
        btn.layer.shadowRadius = 5
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        viewModel.levelSubject.receive(on: DispatchQueue.main).sink { [weak self] level in
            guard let self = self else { return }
            self.canvasView.render(level: level, currentNumber: self.viewModel.currentNumber)
            self.paletteCollectionView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.changesSubject.receive(on: DispatchQueue.main).sink { [weak self] indices in
            self?.canvasView.updatePixels(at: indices)
            self?.paletteCollectionView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.selectedColorIndex.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.paletteCollectionView.reloadData()
            self.canvasView.render(level: self.viewModel.levelSubject.value, currentNumber: self.viewModel.currentNumber)
        }.store(in: &cancellables)
        
        viewModel.isComplete.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            let vc = LevelCompletedViewController(level: self.viewModel.levelSubject.value)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
        }.store(in: &cancellables)
        
        viewModel.isMagicWandMode.sink { [weak self] isActive in
            self?.magicBadgeView.isHidden = !isActive
            if isActive {
                UIView.animate(withDuration: 0.2) {
                    self?.magicButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) { self?.magicButton.transform = .identity }
                }
            }
        }.store(in: &cancellables)
        
        viewModel.isMusicOn.receive(on: DispatchQueue.main).sink { [weak self] isOn in
            let iconName = isOn ? "music.note" : "music.note.list"
            self?.musicButton.setImage(UIImage(systemName: iconName), for: .normal)
            self?.musicButton.alpha = isOn ? 1.0 : 0.5
            if isOn { SoundManager.shared.playBackgroundMusic() }
            else { SoundManager.shared.pauseBackgroundMusic() }
        }.store(in: &cancellables)
        
        viewModel.resetZoomRequest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.canvasView.resetView()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Gestures & Bresenham (Giữ nguyên)
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasView.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        canvasView.addGestureRecognizer(pan)
        canvasView.scrollViewPanGesture.require(toFail: pan)
    }
    
    @objc func handleTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: canvasView)
        if let pixelIndex = canvasView.getPixelIndex(at: location) {
            viewModel.handleTap(atIndex: pixelIndex)
        }
    }
    
    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        let location = g.location(in: canvasView)
        guard let gridPos = canvasView.getGridPosition(at: location) else { return }
        switch g.state {
        case .began:
            lastDragPosition = gridPos
            let idx = canvasView.getIndex(col: gridPos.col, row: gridPos.row)
            viewModel.attemptToColor(indices: [idx])
        case .changed:
            guard let last = lastDragPosition else { lastDragPosition = gridPos; return }
            let points = getPointsOnLine(x0: last.col, y0: last.row, x1: gridPos.col, y1: gridPos.row)
            let indices = points.compactMap { canvasView.getIndex(col: $0.col, row: $0.row) }
            if !indices.isEmpty { viewModel.attemptToColor(indices: indices) }
            lastDragPosition = gridPos
        case .ended, .cancelled: lastDragPosition = nil
        default: break
        }
    }
    
    private func getPointsOnLine(x0: Int, y0: Int, x1: Int, y1: Int) -> [(col: Int, row: Int)] {
        var points: [(Int, Int)] = []
        var x = x0; var y = y0
        let dx = abs(x1 - x); let dy = abs(y1 - y)
        let sx = x0 < x1 ? 1 : -1; let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        while true {
            points.append((x, y))
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 > -dy { err -= dy; x += sx }
            if e2 < dx { err += dx; y += sy }
            if e2 > -dy && e2 < dx { points.append((x - sx, y)) }
        }
        return points
    }
    
    // MARK: - Action Selectors
    @objc private func didTapBack() {
        SoundManager.shared.stopBackgroundMusic()
        animateButton(backButton)
        if let nav = navigationController, nav.viewControllers.count > 1 { nav.popViewController(animated: true) }
        else { dismiss(animated: true, completion: nil) }
    }
    @objc private func didTapMusic() { animateButton(musicButton); viewModel.toggleMusic() }
    @objc private func didTapSearch() {
        animateButton(searchButton)
        if let targetIndex = viewModel.findUncoloredPixelIndex() {
            canvasView.zoomToPixel(at: targetIndex)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    }
    @objc private func didTapMagicWand() { animateButton(magicButton); viewModel.triggerSmartMagic() }
    
    @objc private func didTapFit() {
        animateButton(fitButton)
        viewModel.triggerFitToScreen()
    }
 
    @objc private func didTapCheck() {
        animateButton(checkButton)
        viewModel.triggerCheckButton()
    }
    
    private func animateButton(_ btn: UIButton) {
        UIView.animate(withDuration: 0.1, animations: { btn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }) { _ in
            UIView.animate(withDuration: 0.1) { btn.transform = .identity }
        }
    }
}

// MARK: - UICollectionView (Giữ nguyên)
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
}
