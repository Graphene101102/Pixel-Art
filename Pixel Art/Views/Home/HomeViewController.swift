import UIKit
import PhotosUI

class HomeViewController: UIViewController, UnlockLevelDelegate, ImportPhotoPopupDelegate {
    
    // MARK: - Data
    private var allLevels: [LevelData] = []
    private var displayedLevels: [LevelData] = []
    private var categories: [String] = ["Tất cả"]
    private var currentCategoryIndex = 0
    var pendingUnlockLevel: LevelData?
    
    // MARK: - UI Elements
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let libraryLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Library"
        lbl.font = .systemFont(ofSize: 32, weight: .black)
        lbl.textColor = .black
        return lbl
    }()
    
    // [GIAO DIỆN CŨ] Label Topic có Icon
    private let topicLabel: UILabel = {
        let lbl = UILabel()
        // Tạo icon
        let attachment = NSTextAttachment()
        if let icon = UIImage(named: "Vector") { // Đảm bảo bạn có ảnh tên "Vector" trong Assets
            attachment.image = icon
            attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
        } else {
            // Icon dự phòng nếu không tìm thấy ảnh
            attachment.image = UIImage(systemName: "square.grid.2x2.fill")
            attachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)
        }
        
        let attrString = NSMutableAttributedString(string: "")
        attrString.append(NSAttributedString(attachment: attachment))
        attrString.append(NSAttributedString(string: "  Topic"))
        
        lbl.attributedText = attrString
        lbl.font = .systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .black
        return lbl
    }()
    
    private let plusButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.backgroundColor = .white
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.layer.cornerRadius = 20
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        return btn
    }()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private var categoryCollectionView: UICollectionView!
    private var mainCollectionView: UICollectionView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        
        // Lắng nghe sự kiện lưu game từ GameViewModel để reload Home
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("DidUpdateLevelProgress"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshLocalData()
    }
    
    @objc private func handleProgressUpdate() {
        DispatchQueue.main.async { [weak self] in self?.refreshLocalData() }
    }
    
    // MARK: - Setup UI (Giao diện cũ)
    private func setupUI() {
        view.backgroundColor = .white
        
        // Background
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add Subviews
        view.addSubview(libraryLabel)
        view.addSubview(plusButton)
        view.addSubview(topicLabel) // [GIAO DIỆN CŨ]
        view.addSubview(loadingIndicator)
        
        libraryLabel.translatesAutoresizingMaskIntoConstraints = false
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        topicLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        plusButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        // 1. Category CollectionView (Thu gọn)
        let catLayout = UICollectionViewFlowLayout()
        catLayout.scrollDirection = .horizontal
        catLayout.estimatedItemSize = CGSize(width: 80, height: 35)
        catLayout.minimumInteritemSpacing = 10
        catLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: catLayout)
        categoryCollectionView.backgroundColor = .clear
        categoryCollectionView.showsHorizontalScrollIndicator = false
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        categoryCollectionView.delegate = self
        categoryCollectionView.dataSource = self
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryCollectionView)
        
        // 2. Main CollectionView
        let mainLayout = UICollectionViewFlowLayout()
        let padding: CGFloat = 17
        let itemWidth = (view.frame.width - (padding * 2) - 10) / 2
        // Chiều cao cell = chiều rộng + phần text bên dưới
        mainLayout.itemSize = CGSize(width: itemWidth, height: itemWidth + 40)
        mainLayout.minimumLineSpacing = 20
        mainLayout.sectionInset = UIEdgeInsets(top: 10, left: padding, bottom: 100, right: padding)
        
        mainCollectionView = UICollectionView(frame: .zero, collectionViewLayout: mainLayout)
        mainCollectionView.backgroundColor = .clear
        mainCollectionView.register(LevelListCell.self, forCellWithReuseIdentifier: "LevelListCell")
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainCollectionView)
        
        // Constraints (Căn chỉnh theo giao diện cũ)
        NSLayoutConstraint.activate([
            // Library Label (Top Left)
            libraryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            libraryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Plus Button (Top Right - ngang hàng Library)
            plusButton.centerYAnchor.constraint(equalTo: libraryLabel.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            plusButton.widthAnchor.constraint(equalToConstant: 40),
            plusButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Topic Label (Dưới Library)
            topicLabel.topAnchor.constraint(equalTo: libraryLabel.bottomAnchor, constant: 20),
            topicLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Category CollectionView (Dưới Topic - Thu gọn chiều cao 45)
            categoryCollectionView.topAnchor.constraint(equalTo: topicLabel.bottomAnchor, constant: 15),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 45),
            
            // Main CollectionView (Phần còn lại)
            mainCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 10),
            mainCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Logic Data
    private func loadData() {
        if AppData.shared.hasDataLoaded {
            // 1. Lấy Categories
            self.categories = AppData.shared.preloadedCategories
            self.categoryCollectionView.reloadData()
            
            // 2. Lấy Levels và Merge với Local Save
            let rawLevels = AppData.shared.preloadedLevels
            self.allLevels = rawLevels.map { GameStorageManager.shared.loadLevelProgress(originalLevel: $0) }
            
            // 3. Hiển thị
            self.filterLevels()
            
            return
        }
        
        // --- Nếu vào thẳng Home mà không qua Splash thì load từ firebase ---
        print("⚠️ Fetching data directly in Home")
        loadingIndicator.startAnimating()
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.fetchLevels { [weak self] firebaseLevels in
            guard let self = self else { return }
            self.allLevels = firebaseLevels.map { GameStorageManager.shared.loadLevelProgress(originalLevel: $0) }
            group.leave()
        }
        
        group.enter()
        FirebaseManager.shared.fetchCategories { [weak self] fetchedCats in
            if !fetchedCats.isEmpty {
                var mainCats = fetchedCats.filter { $0 != "Others" }.sorted()
                var finalCats = ["Tất cả"] + mainCats
                if fetchedCats.contains("Others") { finalCats.append("Others") }
                self?.categories = finalCats
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.loadingIndicator.stopAnimating()
            self?.categoryCollectionView.reloadData()
            self?.filterLevels()
        }
    }
    
    private func refreshLocalData() {
        if allLevels.isEmpty { return }
        // Reload lại tiến độ từ file local
        self.allLevels = self.allLevels.map { GameStorageManager.shared.loadLevelProgress(originalLevel: $0) }
        filterLevels()
    }
    
    private func filterLevels() {
        let cat = categories[currentCategoryIndex]
        if cat == "Tất cả" { displayedLevels = allLevels }
        else { displayedLevels = allLevels.filter { $0.category == cat } }
        mainCollectionView.reloadData()
    }
    
    // MARK: - ACTION: Add (Upload Firebase)
    @objc func didTapAdd() {
        // Sử dụng Popup mới
        let popup = ImportPhotoPopupViewController()
        popup.modalPresentationStyle = .overFullScreen
        popup.delegate = self
        present(popup, animated: false)
    }
    
    // Delegate ImportPhotoPopupDelegate
    func didSelectImage(_ image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.onDidCrop = { [weak self] (croppedImage, category) in
            self?.handleFirebaseUpload(image: croppedImage, category: category)
        }
        let nav = UINavigationController(rootViewController: cropVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func handleFirebaseUpload(image: UIImage, category: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newId = UUID().uuidString
            let defaultName = "Pixel Art \(Int.random(in: 100...999))"
            
            // 1. Xử lý ảnh
            if var newLevel = ImageProcessor.shared.processImage(image: image, imageId: newId, targetDimension: 64) {
                newLevel.name = defaultName
                newLevel.category = category
                newLevel.createdAt = Date()
                
                // 2. Upload lên Firebase
                FirebaseManager.shared.uploadLevel(level: newLevel) { [weak self] success in
                    DispatchQueue.main.async {
                        // Cho phép tương tác lại ngay
                        self?.view.isUserInteractionEnabled = true
                        self?.loadingIndicator.stopAnimating() // Tắt loading ngay
                        
                        if success {
                            print("✅ Upload thành công - Cập nhật HomeView ngay lập tức")
                            
                            self?.allLevels.insert(newLevel, at: 0)
                            
                            self?.filterLevels()
                            
                            self?.mainCollectionView.setContentOffset(.zero, animated: true)
                            
                        } else {
                            let alert = UIAlertController(title: "Lỗi", message: "Không thể upload, vui lòng thử lại.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(alert, animated: true)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    self.loadingIndicator.stopAnimating()
                }
            }
        }    }
    
    // MARK: - Game Logic
    private func startGame(level: LevelData) {
        let levelToPlay = GameStorageManager.shared.loadLevelProgress(originalLevel: level)
        let vm = GameViewModel(level: levelToPlay)
        let vc = GameViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Unlock Delegate
    func didTapWatchVideo() {
        let alert = UIAlertController(title: "Watching Ad...", message: "Please wait 2 seconds", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            alert.dismiss(animated: true) {
                guard let self = self, let level = self.pendingUnlockLevel else { return }
                GameStorageManager.shared.markLevelAsUnlocked(id: level.id)
                self.startGame(level: level)
                self.pendingUnlockLevel = nil
            }
        }
    }
    
    func didTapCloseUnlockPopup() {
        pendingUnlockLevel = nil
    }
}

// MARK: - CollectionView Delegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView { return categories.count }
        return displayedLevels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            cell.configure(text: categories[indexPath.item], isSelected: indexPath.item == currentCategoryIndex)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelListCell", for: indexPath) as! LevelListCell
        cell.configure(level: displayedLevels[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            currentCategoryIndex = indexPath.item
            categoryCollectionView.reloadData()
            filterLevels()
        } else {
            let rawLevel = displayedLevels[indexPath.item]
            let isUnlocked = GameStorageManager.shared.isLevelUnlocked(id: rawLevel.id) || !rawLevel.isLocked
            if isUnlocked {
                startGame(level: rawLevel)
            } else {
                pendingUnlockLevel = rawLevel
                let vc = UnlockLevelViewController()
                vc.delegate = self
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }
    }
}
