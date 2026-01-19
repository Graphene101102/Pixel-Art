import UIKit
import PhotosUI

class HomeViewController: UIViewController, UnlockLevelDelegate {
    
    // MARK: - Data
    private var allLevels: [LevelData] = []
    private var displayedLevels: [LevelData] = []
    private var categories: [String] = ["Tất cả"]
    private var currentCategoryIndex = 0
    private var pendingUnlockLevel: LevelData?
    
    // Ẩn hiện nút Plus nếu cần
    var isShowTopPlusButton: Bool = true {
        didSet { plusButton.isHidden = !isShowTopPlusButton }
    }
    
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
    
    private let topicLabel: UILabel = {
        let lbl = UILabel()
        let attachment = NSTextAttachment()
        if let icon = UIImage(named: "Vector") {
            attachment.image = icon
            attachment.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
        }
        let attrString = NSMutableAttributedString(string: "")
        attrString.append(NSAttributedString(attachment: attachment))
        attrString.append(NSAttributedString(string: "  Topic"))
        lbl.attributedText = attrString
        lbl.font = .systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .black
        return lbl
    }()
    
    private var categoryCollectionView: UICollectionView!
    private var mainCollectionView: UICollectionView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Nút Plus (Góc trên phải) -> Upload Firebase
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        
        // Lắng nghe sự kiện lưu game để reload ngay lập tức
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
    
    // Hàm xử lý khi nhận được thông báo
    @objc private func handleProgressUpdate() {
        // Chạy trên main thread để cập nhật UI
        DispatchQueue.main.async { [weak self] in
            self?.refreshLocalData()
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        [libraryLabel, topicLabel, plusButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        plusButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        // Category CollectionView
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
        
        // Main CollectionView
        let mainLayout = UICollectionViewFlowLayout()
        let padding: CGFloat = 17
        let itemWidth = (view.frame.width - (padding * 2) - 10) / 2
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
        
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            libraryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            libraryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            plusButton.centerYAnchor.constraint(equalTo: libraryLabel.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            plusButton.widthAnchor.constraint(equalToConstant: 40),
            plusButton.heightAnchor.constraint(equalToConstant: 40),
            
            topicLabel.topAnchor.constraint(equalTo: libraryLabel.bottomAnchor, constant: 20),
            topicLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            categoryCollectionView.topAnchor.constraint(equalTo: topicLabel.bottomAnchor, constant: 15),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 45),
            
            mainCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 10),
            mainCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Logic Load Data
    private func loadData() {
        loadingIndicator.startAnimating()
        let group = DispatchGroup()
        
        group.enter()
        FirebaseManager.shared.fetchLevels { [weak self] firebaseLevels in
            guard let self = self else { return }
            // Merge with local save
            self.allLevels = firebaseLevels.map { levelFromCloud in
                return GameStorageManager.shared.loadLevelProgress(originalLevel: levelFromCloud)
            }
            group.leave()
        }
        
        group.enter()
        FirebaseManager.shared.fetchCategories { [weak self] fetchedCats in
            if !fetchedCats.isEmpty {
                let otherKey = "Others"
                var mainCats = fetchedCats.filter { $0 != otherKey }
                mainCats.sort()
                var finalCats = ["Tất cả"] + mainCats
                if fetchedCats.contains(otherKey) { finalCats.append(otherKey) }
                self?.categories = finalCats
            } else {
                self?.categories = ["Tất cả", "Động vật", "Đồ ăn", "Phong cảnh", "Nhân vật", "Khác"]
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
        self.allLevels = self.allLevels.map { level in
            return GameStorageManager.shared.loadLevelProgress(originalLevel: level)
        }
        filterLevels()
    }
    
    private func filterLevels() {
        let selectedCategoryName = categories[currentCategoryIndex]
        if selectedCategoryName == "All" || selectedCategoryName == "Tất cả" {
            displayedLevels = allLevels
        } else {
            displayedLevels = allLevels.filter { $0.category == selectedCategoryName }
        }
        mainCollectionView.reloadData()
    }
    
    // MARK: - ACTION: Upload Firebase
    @objc func didTapAdd() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self // HomeVC tự xử lý
        present(picker, animated: true)
    }
    
    private func handleFirebaseUpload(image: UIImage, name: String, category: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let newId = UUID().uuidString
            if var newLevel = ImageProcessor.shared.processImage(image: image, imageId: newId, targetDimension: 64) {
                newLevel.name = name
                newLevel.category = category
                
                // UPLOAD FIREBASE
                FirebaseManager.shared.uploadLevel(level: newLevel) { [weak self] success in
                    DispatchQueue.main.async {
                        self?.view.isUserInteractionEnabled = true
                        if success {
                            self?.loadData() // Reload danh sách
                        } else {
                            self?.loadingIndicator.stopAnimating()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Unlock & Start Game
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
                showUnlockPopup(level: rawLevel)
            }
        }
    }
    
    private func startGame(level: LevelData) {
        let levelToPlay = GameStorageManager.shared.loadLevelProgress(originalLevel: level)
        let vm = GameViewModel(level: levelToPlay)
        let vc = GameViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func showUnlockPopup(level: LevelData) {
        self.pendingUnlockLevel = level
        let vc = UnlockLevelViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
    
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
    func didTapCloseUnlockPopup() { pendingUnlockLevel = nil }
}

// Delegate Extensions
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
}

extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        // Mở Crop VC
                        let cropVC = CropViewController(image: uiImage)
                        // Xử lý kết quả: Upload Firebase
                        cropVC.onDidCrop = { [weak self] (cropped, name, cat) in
                            self?.handleFirebaseUpload(image: cropped, name: name, category: cat)
                        }
                        let nav = UINavigationController(rootViewController: cropVC)
                        nav.modalPresentationStyle = .fullScreen
                        self?.present(nav, animated: true)
                    }
                }
            }
        }
    }
}
