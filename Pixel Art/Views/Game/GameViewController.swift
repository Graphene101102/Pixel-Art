import UIKit
import Combine

class GameViewController: UIViewController, UIGestureRecognizerDelegate, BackgroundSelectionDelegate, GetSupportItemDelegate, ExitConfirmationDelegate {
    
    // ... (Giữ nguyên Properties & UI Elements...)
    private let viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    private var lastDragPosition: (col: Int, row: Int)?
    private var lastProcessedPixelIndex: Int = -1
    private var pendingItemType: GameViewModel.ItemType?
    
    private let backgroundImageView: UIImageView = { let iv = UIImageView(); iv.image = UIImage(named: "BG"); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; return iv }()
    private let canvasView = CanvasView()
    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let bgButton = UIButton(type: .system)
    private let checkButton = UIButton(type: .system)
    private let musicButton = UIButton(type: .system)
    private let bottomPaletteContainer: UIView = { let v = UIView(); v.backgroundColor = .white; v.layer.shadowColor = UIColor.black.cgColor; v.layer.shadowOpacity = 0.08; v.layer.shadowOffset = CGSize(width: 0, height: -3); v.layer.shadowRadius = 8; return v }()
    private var paletteCollectionView: UICollectionView!
    private let toolsStackView = UIStackView()
    private let searchButton = UIButton(type: .system)
    private let magicButton = UIButton(type: .system)
    private let fitButton = UIButton(type: .system)
    private let searchBadgeLabel: UILabel = { let l = UILabel(); l.font = .systemFont(ofSize: 10, weight: .bold); l.textColor = .white; l.textAlignment = .center; l.backgroundColor = .red; l.layer.cornerRadius = 9; l.layer.masksToBounds = true; l.translatesAutoresizingMaskIntoConstraints = false; l.isHidden = true; return l }()
    private let magicBadgeLabel: UILabel = { let l = UILabel(); l.font = .systemFont(ofSize: 10, weight: .bold); l.textColor = .white; l.textAlignment = .center; l.backgroundColor = .red; l.layer.cornerRadius = 9; l.layer.masksToBounds = true; l.translatesAutoresizingMaskIntoConstraints = false; l.isHidden = true; return l }()
    private let magicModeIndicatorView = UIView()
    
    init(viewModel: GameViewModel) { self.viewModel = viewModel; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() { super.viewDidLoad(); setupUI(); setupGestures(); bindViewModel(); updateBadges(); NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil); NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil) }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: animated); viewModel.refreshState() }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); viewModel.saveProgress(); if SoundManager.shared.isMusicEnabled { SoundManager.shared.playBackgroundMusic() }; navigationController?.interactivePopGestureRecognizer?.isEnabled = false; viewModel.startGameplayTimer() }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); viewModel.stopGameplayTimer(); viewModel.saveProgress(); if self.isMovingFromParent || self.isBeingDismissed { SoundManager.shared.pauseBackgroundMusic() }; navigationController?.interactivePopGestureRecognizer?.isEnabled = true }
    @objc private func appDidEnterBackground() { viewModel.stopGameplayTimer(); viewModel.saveProgress() }
    @objc private func appWillEnterForeground() { viewModel.startGameplayTimer() }
    deinit { NotificationCenter.default.removeObserver(self) }
    
    private func setupUI() {
        view.backgroundColor = .white
        [backgroundImageView, canvasView, topBarView, musicButton, bottomPaletteContainer, toolsStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; view.addSubview($0) }
        [backButton, bgButton, checkButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; topBarView.addSubview($0) }
        configureSquareButton(backButton, iconName: "backIcon"); backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        configureSquareButton(bgButton, iconName: "bgIcon"); bgButton.addTarget(self, action: #selector(didTapBgSettings), for: .touchUpInside)
        configureSquareButton(checkButton, iconName: "Badge Check"); checkButton.addTarget(self, action: #selector(didTapCheck), for: .touchUpInside)
        configureSquareButton(musicButton, iconName: "musicIcon"); musicButton.addTarget(self, action: #selector(didTapMusic), for: .touchUpInside)
        let layout = UICollectionViewFlowLayout(); layout.itemSize = CGSize(width: 50, height: 50); layout.scrollDirection = .horizontal; layout.minimumInteritemSpacing = 16; layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        paletteCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout); paletteCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell"); paletteCollectionView.dataSource = self; paletteCollectionView.delegate = self; paletteCollectionView.backgroundColor = .clear; paletteCollectionView.showsHorizontalScrollIndicator = false; paletteCollectionView.translatesAutoresizingMaskIntoConstraints = false; bottomPaletteContainer.addSubview(paletteCollectionView)
        toolsStackView.axis = .horizontal; toolsStackView.distribution = .equalSpacing; toolsStackView.alignment = .center; toolsStackView.spacing = 16
        configureToolButton(searchButton, iconName: "searchIcon"); searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        configureToolButton(magicButton, iconName: "magicIcon"); magicButton.addTarget(self, action: #selector(didTapMagicWand), for: .touchUpInside)
        magicModeIndicatorView.backgroundColor = .red; magicModeIndicatorView.layer.cornerRadius = 3; magicModeIndicatorView.translatesAutoresizingMaskIntoConstraints = false; magicModeIndicatorView.isHidden = true; magicButton.addSubview(magicModeIndicatorView)
        configureToolButton(fitButton, iconName: "zoomIcon"); fitButton.addTarget(self, action: #selector(didTapFit), for: .touchUpInside)
        [searchButton, magicButton, fitButton].forEach { toolsStackView.addArrangedSubview($0) }
        searchButton.addSubview(searchBadgeLabel); magicButton.addSubview(magicBadgeLabel)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor), backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor), backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor), backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: view.topAnchor), canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor), canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor), canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), topBarView.heightAnchor.constraint(equalToConstant: 50),
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor), backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor), bgButton.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor), bgButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor), checkButton.trailingAnchor.constraint(equalTo: topBarView.trailingAnchor), checkButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor),
            musicButton.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 16), musicButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomPaletteContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor), bottomPaletteContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor), bottomPaletteContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            paletteCollectionView.leadingAnchor.constraint(equalTo: bottomPaletteContainer.leadingAnchor), paletteCollectionView.trailingAnchor.constraint(equalTo: bottomPaletteContainer.trailingAnchor), paletteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), paletteCollectionView.heightAnchor.constraint(equalToConstant: 60),
            bottomPaletteContainer.topAnchor.constraint(equalTo: paletteCollectionView.topAnchor, constant: -15),
            toolsStackView.bottomAnchor.constraint(equalTo: bottomPaletteContainer.topAnchor, constant: -20), toolsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), toolsStackView.heightAnchor.constraint(equalToConstant: 50),
            magicModeIndicatorView.topAnchor.constraint(equalTo: magicButton.topAnchor, constant: 5), magicModeIndicatorView.leadingAnchor.constraint(equalTo: magicButton.leadingAnchor, constant: 5), magicModeIndicatorView.widthAnchor.constraint(equalToConstant: 6), magicModeIndicatorView.heightAnchor.constraint(equalToConstant: 6),
            searchBadgeLabel.topAnchor.constraint(equalTo: searchButton.topAnchor, constant: -5), searchBadgeLabel.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor, constant: 5), searchBadgeLabel.widthAnchor.constraint(equalToConstant: 18), searchBadgeLabel.heightAnchor.constraint(equalToConstant: 18),
            magicBadgeLabel.topAnchor.constraint(equalTo: magicButton.topAnchor, constant: -5), magicBadgeLabel.trailingAnchor.constraint(equalTo: magicButton.trailingAnchor, constant: 5), magicBadgeLabel.widthAnchor.constraint(equalToConstant: 18), magicBadgeLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    private func configureSquareButton(_ btn: UIButton, iconName: String) { btn.setImage(UIImage(named: iconName) ?? UIImage(systemName: "questionmark.square"), for: .normal); btn.tintColor = UIColor(hex: "#3475CB"); btn.backgroundColor = .white; btn.layer.cornerRadius = 12; btn.layer.borderWidth = 1.5; btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor; btn.layer.shadowColor = UIColor.black.cgColor; btn.layer.shadowOpacity = 0.1; btn.layer.shadowOffset = CGSize(width: 0, height: 2); btn.layer.shadowRadius = 4; btn.translatesAutoresizingMaskIntoConstraints = false; btn.widthAnchor.constraint(equalToConstant: 44).isActive = true; btn.heightAnchor.constraint(equalToConstant: 44).isActive = true; btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) }
    private func configureToolButton(_ btn: UIButton, iconName: String) { btn.setImage(UIImage(named: iconName) ?? UIImage(systemName: "questionmark.circle"), for: .normal); btn.tintColor = UIColor(hex: "#3475CB"); btn.backgroundColor = .white; btn.layer.cornerRadius = 14; btn.layer.borderWidth = 1.5; btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor; btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor; btn.layer.shadowOpacity = 0.1; btn.layer.shadowOffset = CGSize(width: 0, height: 3); btn.layer.shadowRadius = 5; btn.translatesAutoresizingMaskIntoConstraints = false; btn.widthAnchor.constraint(equalToConstant: 50).isActive = true; btn.heightAnchor.constraint(equalToConstant: 50).isActive = true; btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) }
    
    private func bindViewModel() {
        viewModel.levelSubject.receive(on: DispatchQueue.main).sink { [weak self] level in
            guard let self = self else { return }
            self.canvasView.render(level: level, currentNumber: self.viewModel.currentNumber)
            self.paletteCollectionView.reloadData()
        }.store(in: &cancellables)
        viewModel.loadInitialLevel()
        viewModel.changesSubject.receive(on: DispatchQueue.main).sink { [weak self] indices in
            guard let self = self else { return }
            self.canvasView.updatePixels(at: indices, with: self.viewModel.currentLevelData)
            self.paletteCollectionView.reloadData()
        }.store(in: &cancellables)
        viewModel.selectedColorIndex.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            self.paletteCollectionView.reloadData(); self.canvasView.render(level: self.viewModel.currentLevelData, currentNumber: self.viewModel.currentNumber)
        }.store(in: &cancellables)
        viewModel.isComplete.receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self = self else { return }
            let vc = LevelCompletedViewController(level: self.viewModel.currentLevelData); vc.modalPresentationStyle = .overFullScreen; vc.modalTransitionStyle = .crossDissolve; self.present(vc, animated: true)
        }.store(in: &cancellables)
        viewModel.isMagicWandMode.sink { [weak self] isActive in
            self?.magicModeIndicatorView.isHidden = !isActive
            if isActive { UIView.animate(withDuration: 0.2) { self?.magicButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1) } completion: { _ in UIView.animate(withDuration: 0.2) { self?.magicButton.transform = .identity } } }
        }.store(in: &cancellables)
        viewModel.isMusicOn.receive(on: DispatchQueue.main).sink { [weak self] isOn in
            self?.musicButton.alpha = isOn ? 1.0 : 0.5; if isOn { SoundManager.shared.playBackgroundMusic() } else { SoundManager.shared.pauseBackgroundMusic() }
        }.store(in: &cancellables)
        viewModel.resetZoomRequest.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.canvasView.resetView() }.store(in: &cancellables)
    }
    
    private func updateBadges() {
        let sCount = viewModel.searchItemCount; searchBadgeLabel.text = "\(sCount)"; searchBadgeLabel.isHidden = sCount == 0
        let mCount = viewModel.magicWandCount; magicBadgeLabel.text = "\(mCount)"; magicBadgeLabel.isHidden = mCount == 0
    }
    
    // Actions
    @objc private func didTapBack() { SoundManager.shared.stopBackgroundMusic(); animateButton(backButton); viewModel.saveProgress(); let popup = ExitConfirmationViewController(); popup.delegate = self; present(popup, animated: true) }
    @objc private func didTapBgSettings() { animateButton(bgButton); let vc = BackgroundSelectionViewController(); vc.modalPresentationStyle = .overFullScreen; vc.modalTransitionStyle = .crossDissolve; vc.delegate = self; present(vc, animated: true) }
    func didSelectBackgroundColor(_ color: UIColor) { backgroundImageView.image = nil; backgroundImageView.backgroundColor = color }
    func didSelectBackgroundImage(_ image: UIImage) { backgroundImageView.backgroundColor = .clear; backgroundImageView.image = image }
    @objc private func didTapMusic() { animateButton(musicButton); viewModel.toggleMusic() }
    @objc private func didTapFit() { animateButton(fitButton); viewModel.triggerFitToScreen() }
    @objc private func didTapCheck() { animateButton(checkButton); viewModel.triggerCheckButton() }
    @objc private func didTapSearch() { animateButton(searchButton); let currentNum = viewModel.currentNumber; let level = viewModel.currentLevelData; let isCompleted = !level.pixels.contains { $0.number == currentNum && !$0.isColored }; if isCompleted { return }; if viewModel.tryUseSearch() { if let targetIndex = viewModel.findUncoloredPixelIndex() { canvasView.zoomToPixel(at: targetIndex); UIImpactFeedbackGenerator(style: .medium).impactOccurred(); updateBadges() } } else { showItemAdPopup(type: .search) } }
    @objc private func didTapMagicWand() { animateButton(magicButton); if viewModel.tryUseMagicWand() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(); updateBadges() } else { showItemAdPopup(type: .magicWand) } }
    private func showItemAdPopup(type: GameViewModel.ItemType) { self.pendingItemType = type; let vc = GetSupportItemViewController(); vc.loadViewIfNeeded(); vc.configurePopup(for: type); vc.delegate = self; vc.modalPresentationStyle = .overFullScreen; vc.modalTransitionStyle = .crossDissolve; present(vc, animated: true) }
    func didTapWatchVideoForSupport() { let alert = UIAlertController(title: "Loading Ad...", message: "Please wait", preferredStyle: .alert); present(alert, animated: true); DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in alert.dismiss(animated: true) { guard let self = self, let type = self.pendingItemType else { return }; self.viewModel.rewardItems(type: type); self.updateBadges(); let msg = type == .magicWand ? "Received 3 Magic Wands!" : "Received 3 Search Hints!"; let success = UIAlertController(title: "Reward Granted", message: msg, preferredStyle: .alert); success.addAction(UIAlertAction(title: "OK", style: .default)); self.present(success, animated: true); self.pendingItemType = nil } } }
    func didTapCloseSupportPopup() { pendingItemType = nil }
    private func animateButton(_ btn: UIButton) { UIView.animate(withDuration: 0.1, animations: { btn.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }) { _ in UIView.animate(withDuration: 0.1) { btn.transform = .identity } } }
    func didConfirmExit() { viewModel.saveProgress(); if let nav = navigationController, nav.viewControllers.count > 1 { nav.popViewController(animated: true) } else { let transition = CATransition(); transition.duration = 0.4; transition.type = .push; transition.subtype = .fromLeft; transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut); view.window?.layer.add(transition, forKey: kCATransition); dismiss(animated: false, completion: nil) } }
    
    // MARK: - Gestures & Vẽ (Optimized Batch Processing)
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))); canvasView.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))); pan.maximumNumberOfTouches = 1; pan.delegate = self; canvasView.addGestureRecognizer(pan)
        canvasView.scrollViewPanGesture.require(toFail: pan)
    }
    
    @objc func handleTap(_ g: UITapGestureRecognizer) {
        let location = g.location(in: canvasView)
        if let pixelIndex = canvasView.getPixelIndex(at: location) { viewModel.handleTap(atIndex: pixelIndex) }
    }
    
    // [HANDLE PAN: GOM NHÓM ĐIỂM]
    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        let location = g.location(in: canvasView)
        guard let gridPos = canvasView.getGridPosition(at: location) else { return }
        
        let gridW = viewModel.currentLevelData.gridWidth
        let gridH = viewModel.currentLevelData.gridHeight
        let pixelIndex = gridPos.row * gridW + gridPos.col
        
        // Màu hiện tại cho Animation
        let selectedIndex = viewModel.selectedColorIndex.value
        let currentColor: UIColor
        if selectedIndex < viewModel.currentLevelData.palette.count {
            currentColor = viewModel.currentLevelData.palette[selectedIndex]
        } else {
            currentColor = .black
        }
        
        switch g.state {
        case .began:
            lastDragPosition = gridPos
            lastProcessedPixelIndex = pixelIndex
            if viewModel.canStartPainting(at: pixelIndex) {
                // Batch paint 1 điểm
                canvasView.batchPaintPixels(at: [pixelIndex], color: currentColor)
                viewModel.attemptToColor(indices: [pixelIndex])
            }
            
        case .changed:
            guard let last = lastDragPosition else { lastDragPosition = gridPos; return }
            if pixelIndex == lastProcessedPixelIndex { return }
            
            // --- INLINE BRESENHAM ---
            var x = last.col; var y = last.row
            let x1 = gridPos.col; let y1 = gridPos.row
            let dx = abs(x1 - x); let dy = abs(y1 - y)
            let sx = x < x1 ? 1 : -1; let sy = y < y1 ? 1 : -1
            var err = dx - dy
            
            var indicesToSync: [Int] = []
            
            while true {
                if x >= 0 && x < gridW && y >= 0 && y < gridH {
                    let idx = y * gridW + x
                    
                    if idx != lastProcessedPixelIndex {
                        if viewModel.canStartPainting(at: idx) {
                            indicesToSync.append(idx)
                        }
                        lastProcessedPixelIndex = idx
                    }
                }
                
                if x == x1 && y == y1 { break }
                let e2 = 2 * err; let prevX = x; let prevY = y
                if e2 > -dy { err -= dy; x += sx }
                if e2 < dx { err += dx; y += sy }
                
                // Staircase Fill
                if x != prevX && y != prevY {
                    let cx = x; let cy = prevY
                    if cx >= 0 && cx < gridW && cy >= 0 && cy < gridH {
                        let idx = cy * gridW + cx
                        if idx != lastProcessedPixelIndex {
                            if viewModel.canStartPainting(at: idx) {
                                indicesToSync.append(idx)
                            }
                            lastProcessedPixelIndex = idx
                        }
                    }
                }
            }
            
            // [BATCH] Gửi danh sách điểm đi vẽ (Animation có giới hạn số lượng trong hàm batchPaintPixels)
            if !indicesToSync.isEmpty {
                canvasView.batchPaintPixels(at: indicesToSync, color: currentColor)
                viewModel.attemptToColor(indices: indicesToSync)
            }
            
            lastDragPosition = gridPos
            
        case .ended, .cancelled:
            lastDragPosition = nil
            lastProcessedPixelIndex = -1
        default: break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer, panGesture.view == canvasView {
            let location = panGesture.location(in: canvasView)
            if let index = canvasView.getPixelIndex(at: location) {
                if viewModel.canStartPainting(at: index) { return true }
            }
            return false
        }
        return true
    }
}

extension GameViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return viewModel.currentLevelData.palette.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
        let level = viewModel.currentLevelData
        let number = indexPath.item + 1
        let isCompleted = !level.pixels.contains { $0.number == number && !$0.isColored }
        cell.configure(color: level.palette[indexPath.item], number: number, isSelected: indexPath.item == viewModel.selectedColorIndex.value, isCompleted: isCompleted)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { viewModel.selectedColorIndex.send(indexPath.item) }
}
