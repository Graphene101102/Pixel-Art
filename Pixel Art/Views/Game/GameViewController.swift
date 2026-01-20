import UIKit
import Combine

class GameViewController: UIViewController, UIGestureRecognizerDelegate, BackgroundSelectionDelegate, GetSupportItemDelegate, ExitConfirmationDelegate {
    
    // MARK: - Properties
    private let viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // Biến hỗ trợ vẽ (kéo tay)
    private var lastDragPosition: (col: Int, row: Int)?
    
    // Biến lưu loại item đang chờ nhận thưởng (xem quảng cáo)
    private var pendingItemType: GameViewModel.ItemType?
    
    // MARK: - UI Elements
    
    // 1. Ảnh nền (Background)
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // 2. Canvas (Vùng vẽ tranh)
    private let canvasView = CanvasView()
    
    // 3. Top Bar (Chứa nút Back, BG Settings, Check)
    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let bgButton = UIButton(type: .system)
    private let checkButton = UIButton(type: .system)
    
    // 4. Nút nhạc (Nằm dưới Top Bar bên phải)
    private let musicButton = UIButton(type: .system)
    
    // 5. Palette Màu (Thanh chọn màu bên dưới)
    private let bottomPaletteContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        // Shadow cho đẹp
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -3)
        v.layer.shadowRadius = 8
        return v
    }()
    
    private var paletteCollectionView: UICollectionView!
    
    // 6. Công cụ hỗ trợ (Search, Magic Wand, Zoom Fit)
    private let toolsStackView = UIStackView()
    private let searchButton = UIButton(type: .system)
    private let magicButton = UIButton(type: .system)
    private let fitButton = UIButton(type: .system)
    
    // 7. Badge (Số lượng item còn lại)
    private let searchBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .red
        l.layer.cornerRadius = 9
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true // Mặc định ẩn
        return l
    }()
    
    private let magicBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .red
        l.layer.cornerRadius = 9
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()
    
    // Chấm đỏ chỉ báo đang bật chế độ Magic Wand
    private let magicModeIndicatorView = UIView()
    
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
        
        // Cập nhật số lượng item lần đầu
        updateBadges()
        
        // Lắng nghe khi app bị ẩn xuống (Về Home/Cuộc gọi tới)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Lắng nghe app mở lại
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        viewModel.refreshState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Tự động lưu 1 lần khi vào game để chắc chắn file tồn tại
        viewModel.saveProgress()
        
        if SoundManager.shared.isMusicEnabled {
                    SoundManager.shared.playBackgroundMusic()
                }
        
        // Tắt tính năng vuốt cạnh để back (tránh vuốt nhầm khi tô màu)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        viewModel.startGameplayTimer()
    }
    
    // [CỰC KỲ QUAN TRỌNG] Lưu dữ liệu khi thoát màn hình
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.stopGameplayTimer()
        
        // Lưu ngay lập tức
        viewModel.saveProgress()
        
        if self.isMovingFromParent || self.isBeingDismissed {
            SoundManager.shared.pauseBackgroundMusic()
        }
        
        // Bật lại tính năng vuốt cạnh cho các màn hình khác
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    // [CỰC KỲ QUAN TRỌNG] Lưu dữ liệu khi app ẩn
    @objc private func appDidEnterBackground() {
        viewModel.stopGameplayTimer()
        viewModel.saveProgress()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Khi App quay lại (Foreground)
    @objc private func appWillEnterForeground() {
        viewModel.startGameplayTimer()
    }
    
    // MARK: - Setup UI Constraints
    private func setupUI() {
        view.backgroundColor = .white
        
        // 1. Background
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // 2. Canvas
        canvasView.backgroundColor = .clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        // 3. Top Bar
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBarView)
        
        configureSquareButton(backButton, iconName: "backIcon")
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        configureSquareButton(bgButton, iconName: "bgIcon")
        bgButton.addTarget(self, action: #selector(didTapBgSettings), for: .touchUpInside)
        
        configureSquareButton(checkButton, iconName: "Badge Check")
        checkButton.addTarget(self, action: #selector(didTapCheck), for: .touchUpInside)
        
        [backButton, bgButton, checkButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            topBarView.addSubview($0)
        }
        
        // 4. Music Button
        configureSquareButton(musicButton, iconName: "musicIcon")
        musicButton.translatesAutoresizingMaskIntoConstraints = false
        musicButton.addTarget(self, action: #selector(didTapMusic), for: .touchUpInside)
        view.addSubview(musicButton)
        
        // 5. Bottom Palette Container
        bottomPaletteContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomPaletteContainer)
        
        // Collection View
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
        
        // 6. Tools Stack View
        toolsStackView.axis = .horizontal
        toolsStackView.distribution = .equalSpacing
        toolsStackView.alignment = .center
        toolsStackView.spacing = 16
        toolsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolsStackView)
        
        configureToolButton(searchButton, iconName: "searchIcon")
        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        
        configureToolButton(magicButton, iconName: "magicIcon")
        magicButton.addTarget(self, action: #selector(didTapMagicWand), for: .touchUpInside)
        
        // Magic Indicator (Chấm đỏ)
        magicModeIndicatorView.backgroundColor = .red
        magicModeIndicatorView.layer.cornerRadius = 3
        magicModeIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        magicModeIndicatorView.isHidden = true
        magicButton.addSubview(magicModeIndicatorView)
        
        configureToolButton(fitButton, iconName: "zoomIcon")
        fitButton.addTarget(self, action: #selector(didTapFit), for: .touchUpInside)
        
        [searchButton, magicButton, fitButton].forEach { toolsStackView.addArrangedSubview($0) }
        
        // 7. Add Badges
        searchButton.addSubview(searchBadgeLabel)
        magicButton.addSubview(magicBadgeLabel)
        
        // --- AUTO LAYOUT ---
        NSLayoutConstraint.activate([
            // Background
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Canvas
            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Top Bar Container
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topBarView.heightAnchor.constraint(equalToConstant: 50),
            
            // Buttons in Top Bar
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            bgButton.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            bgButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            checkButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor),
            checkButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            
            // Music Button (Dưới Top Bar)
            musicButton.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 16),
            musicButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Bottom Palette Container
            bottomPaletteContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaletteContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPaletteContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // CollectionView (Bên trong Container)
            paletteCollectionView.leadingAnchor.constraint(equalTo: bottomPaletteContainer.leadingAnchor),
            paletteCollectionView.trailingAnchor.constraint(equalTo: bottomPaletteContainer.trailingAnchor),
            paletteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            paletteCollectionView.heightAnchor.constraint(equalToConstant: 60),
            
            // Ràng buộc chiều cao container theo collection view
            bottomPaletteContainer.topAnchor.constraint(equalTo: paletteCollectionView.topAnchor, constant: -15),
            
            // Tools Stack View (Nằm trên Palette)
            toolsStackView.bottomAnchor.constraint(equalTo: bottomPaletteContainer.topAnchor, constant: -20),
            toolsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toolsStackView.heightAnchor.constraint(equalToConstant: 50),
            
            // Magic Indicator (Chấm nhỏ trên nút Magic)
            magicModeIndicatorView.topAnchor.constraint(equalTo: magicButton.topAnchor, constant: 5),
            magicModeIndicatorView.leadingAnchor.constraint(equalTo: magicButton.leadingAnchor, constant: 5),
            magicModeIndicatorView.widthAnchor.constraint(equalToConstant: 6),
            magicModeIndicatorView.heightAnchor.constraint(equalToConstant: 6),
            
            // Badges
            searchBadgeLabel.topAnchor.constraint(equalTo: searchButton.topAnchor, constant: -5),
            searchBadgeLabel.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor, constant: 5),
            searchBadgeLabel.widthAnchor.constraint(equalToConstant: 18),
            searchBadgeLabel.heightAnchor.constraint(equalToConstant: 18),
            
            magicBadgeLabel.topAnchor.constraint(equalTo: magicButton.topAnchor, constant: -5),
            magicBadgeLabel.trailingAnchor.constraint(equalTo: magicButton.trailingAnchor, constant: 5),
            magicBadgeLabel.widthAnchor.constraint(equalToConstant: 18),
            magicBadgeLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    // Helper tạo nút vuông (Top Bar)
    private func configureSquareButton(_ btn: UIButton, iconName: String) {
        if let image = UIImage(named: iconName) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "questionmark.square"), for: .normal)
        }
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        // Shadow
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // Helper tạo nút tròn (Tools)
    private func configureToolButton(_ btn: UIButton, iconName: String) {
        if let image = UIImage(named: iconName) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        }
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
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
    
    // MARK: - Binding & Update Logic
    private func bindViewModel() {
        
        // [QUAN TRỌNG] 1. Load lần đầu: Cập nhật Canvas khi có LevelData mới
        // Dùng PassthroughSubject (levelSubject) để lắng nghe
        viewModel.levelSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self = self else { return }
                self.canvasView.render(level: level, currentNumber: self.viewModel.currentNumber)
                self.paletteCollectionView.reloadData()
            }.store(in: &cancellables)
        
        // Gọi hàm load ban đầu
        viewModel.loadInitialLevel()
        
        // [QUAN TRỌNG] 2. Cập nhật tối ưu: Chỉ vẽ lại các pixel thay đổi
        // Truyền thêm with: self.viewModel.currentLevelData để fix lỗi không hiển thị màu ngay
        viewModel.changesSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indices in
                guard let self = self else { return }
                self.canvasView.updatePixels(at: indices, with: self.viewModel.currentLevelData)
                self.paletteCollectionView.reloadData()
            }.store(in: &cancellables)
        
        // 3. Khi chọn màu mới -> Render lại lớp phủ (Highlight số)
        viewModel.selectedColorIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.paletteCollectionView.reloadData()
                // Render lại nhưng chỉ vẽ overlay, không tính toán nặng
                self.canvasView.render(level: self.viewModel.currentLevelData, currentNumber: self.viewModel.currentNumber)
            }.store(in: &cancellables)
        
        // 4. Khi hoàn thành Level
        viewModel.isComplete.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            let vc = LevelCompletedViewController(level: self.viewModel.currentLevelData)
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true)
        }.store(in: &cancellables)
        
        // 5. Chế độ Magic Wand
        viewModel.isMagicWandMode.sink { [weak self] isActive in
            self?.magicModeIndicatorView.isHidden = !isActive
            if isActive {
                UIView.animate(withDuration: 0.2) {
                    self?.magicButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) { self?.magicButton.transform = .identity }
                }
            }
        }.store(in: &cancellables)
        
        // 6. Trạng thái nhạc
        viewModel.isMusicOn.receive(on: DispatchQueue.main).sink { [weak self] isOn in
            self?.musicButton.alpha = isOn ? 1.0 : 0.5
            if isOn { SoundManager.shared.playBackgroundMusic() }
            else { SoundManager.shared.pauseBackgroundMusic() }
        }.store(in: &cancellables)
        
        // 7. Reset Zoom
        viewModel.resetZoomRequest.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.canvasView.resetView()
        }.store(in: &cancellables)
    }
    
    private func updateBadges() {
        let sCount = viewModel.searchItemCount
        searchBadgeLabel.text = "\(sCount)"
        searchBadgeLabel.isHidden = sCount == 0
        
        let mCount = viewModel.magicWandCount
        magicBadgeLabel.text = "\(mCount)"
        magicBadgeLabel.isHidden = mCount == 0
    }
    
    // MARK: - Actions
    
    // Nút Back
    @objc private func didTapBack() {
        SoundManager.shared.stopBackgroundMusic()
        animateButton(backButton)
        
        // Lưu lần cuối trước khi thoát
        viewModel.saveProgress()
        
        let popup = ExitConfirmationViewController()
                popup.delegate = self
                present(popup, animated: true)
    }
    
    // Nút chọn nền (BG)
    @objc private func didTapBgSettings() {
        animateButton(bgButton)
        let vc = BackgroundSelectionViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        present(vc, animated: true)
    }
    
    // Delegate chọn nền
    func didSelectBackgroundColor(_ color: UIColor) {
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = color
    }
    func didSelectBackgroundImage(_ image: UIImage) {
        backgroundImageView.backgroundColor = .clear
        backgroundImageView.image = image
    }
    
    // Các nút khác
    @objc private func didTapMusic() { animateButton(musicButton); viewModel.toggleMusic() }
    @objc private func didTapFit() { animateButton(fitButton); viewModel.triggerFitToScreen() }
    @objc private func didTapCheck() { animateButton(checkButton); viewModel.triggerCheckButton() }
    
    // Nút Search (Gợi ý)
    @objc private func didTapSearch() {
        animateButton(searchButton)
        if viewModel.tryUseSearch() {
            if let targetIndex = viewModel.findUncoloredPixelIndex() {
                canvasView.zoomToPixel(at: targetIndex)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                updateBadges()
            }
        } else {
            showItemAdPopup(type: .search)
        }
    }
    
    // Nút Magic Wand
    @objc private func didTapMagicWand() {
        animateButton(magicButton)
        if viewModel.tryUseMagicWand() {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            updateBadges()
        } else {
            showItemAdPopup(type: .magicWand)
        }
    }
    
    // Popup xem quảng cáo nhận item
    private func showItemAdPopup(type: GameViewModel.ItemType) {
        self.pendingItemType = type
        let vc = GetSupportItemViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
    
    // Delegate Quảng cáo
    func didTapWatchVideoForSupport() {
        let alert = UIAlertController(title: "Loading Ad...", message: "Please wait", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            alert.dismiss(animated: true) {
                guard let self = self, let type = self.pendingItemType else { return }
                self.viewModel.rewardItems(type: type)
                self.updateBadges()
                
                let msg = type == .magicWand ? "Received 3 Magic Wands!" : "Received 3 Search Hints!"
                let success = UIAlertController(title: "Reward Granted", message: msg, preferredStyle: .alert)
                success.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(success, animated: true)
                self.pendingItemType = nil
            }
        }
    }
    func didTapCloseSupportPopup() { pendingItemType = nil }
    
    // MARK: - Gestures & Vẽ (Bresenham)
    private func setupGestures() {
        // Tap: Tô 1 điểm
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasView.addGestureRecognizer(tap)
        
        // Pan: Tô theo đường vẽ
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        canvasView.addGestureRecognizer(pan)
        
        // ScrollView chỉ được phép scroll nếu Pan vẽ thất bại
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
            // Dùng thuật toán Bresenham để nối các điểm bị đứt khi vuốt nhanh
            let points = getPointsOnLine(x0: last.col, y0: last.row, x1: gridPos.col, y1: gridPos.row)
            let indices = points.compactMap { canvasView.getIndex(col: $0.col, row: $0.row) }
            if !indices.isEmpty { viewModel.attemptToColor(indices: indices) }
            lastDragPosition = gridPos
        case .ended, .cancelled:
            lastDragPosition = nil
        default: break
        }
    }
    
    // Conflict resolution: Cho phép Pan vẽ đè lên ScrollView nếu chạm vào ô màu hợp lệ
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer, panGesture.view == canvasView {
            let location = panGesture.location(in: canvasView)
            if let index = canvasView.getPixelIndex(at: location) {
                // Nếu ô này có thể tô -> Ưu tiên vẽ (trả về true)
                if viewModel.canStartPainting(at: index) { return true }
            }
            // Ngược lại -> Ưu tiên scroll/zoom (trả về false)
            return false
        }
        return true
    }
    
    // Thuật toán Bresenham nối điểm
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
            // Thêm điểm phụ để nét vẽ mượt hơn (optional)
            if e2 > -dy && e2 < dx { points.append((x - sx, y)) }
        }
        return points
    }
    
    private func animateButton(_ btn: UIButton) {
        UIView.animate(withDuration: 0.1, animations: { btn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }) { _ in
            UIView.animate(withDuration: 0.1) { btn.transform = .identity }
        }
    }
    
    func didConfirmExit() {
            // Lưu dữ liệu lần cuối
            viewModel.saveProgress()
            
            if let nav = navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
}

// MARK: - Extensions: CollectionView Delegate
extension GameViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.currentLevelData.palette.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
        let level = viewModel.currentLevelData
        let number = indexPath.item + 1
        
        // Kiểm tra xem số này đã tô xong hết chưa
        let isCompleted = !level.pixels.contains { $0.number == number && !$0.isColored }
        
        cell.configure(
            color: level.palette[indexPath.item],
            number: number,
            isSelected: indexPath.item == viewModel.selectedColorIndex.value,
            isCompleted: isCompleted
        )
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedColorIndex.send(indexPath.item)
    }
    
    
}
