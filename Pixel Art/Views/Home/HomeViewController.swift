import UIKit
import PhotosUI

class HomeViewController: UIViewController, UnlockLevelDelegate, ImportPhotoPopupDelegate, DifficultySelectionDelegate {
    
    // Ẩn/ Hiện plusbutton
    var showPlusButton: Bool = true {
        didSet {
            plusButton.isHidden = !showPlusButton
        }
    }
    
    // MARK: - Data Properties
    private var allLevels: [LevelData] = []  // Chứa tất cả level (Gốc Firebase + Merge Local)
    
    // Gom nhóm để hiển thị 1 hình đại diện cho 3 cấp độ
    private var groupedLevels: [LevelData] = []
    private var allLevelsMap: [String: [LevelData]] = [:] // Map groupId -> [Easy, Medium, Hard]
    
    private var displayedLevels: [LevelData] = []
    private var categories: [String] = ["All"]
    private var currentCategoryIndex = 0
    var pendingUnlockLevel: LevelData?
    
    // Biến cờ để phân biệt nguồn (Plus vs Middle)
    private var isCreatingFirebaseLevels: Bool = false
    
    // MARK: - UI Elements
    private let libraryLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Library"
        lbl.font = .systemFont(ofSize: 32, weight: .black)
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
        loadDataFromFirebase()
        
        // Lắng nghe khi có thay đổi tiến độ (Save game local) để reload UI
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("DidUpdateLevelProgress"),
            object: nil
        )
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        refreshDataDisplay()
    }
    
    @objc private func handleProgressUpdate() {
        DispatchQueue.main.async { [weak self] in self?.refreshDataDisplay() }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let bgView = AppBackgroundView()
        view.addSubview(bgView)
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(bgView)
        
        view.addSubview(libraryLabel)
        view.addSubview(plusButton)
        view.addSubview(loadingIndicator)
        
        // Cập nhật trạng thái hiển thị ban đầu dựa trên biến
        plusButton.isHidden = !showPlusButton
        
        libraryLabel.translatesAutoresizingMaskIntoConstraints = false
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        plusButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
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
        
        let mainLayout = UICollectionViewFlowLayout()
        let padding: CGFloat = 17
        let itemWidth = (view.frame.width - (padding * 2) - 10) / 2
        mainLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        mainLayout.minimumLineSpacing = 20
        mainLayout.sectionInset = UIEdgeInsets(top: 10, left: padding, bottom: 100, right: padding)
        
        mainCollectionView = UICollectionView(frame: .zero, collectionViewLayout: mainLayout)
        mainCollectionView.backgroundColor = .clear
        mainCollectionView.register(LevelListCell.self, forCellWithReuseIdentifier: "LevelListCell")
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainCollectionView)
        
        NSLayoutConstraint.activate([
            libraryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            libraryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            plusButton.centerYAnchor.constraint(equalTo: libraryLabel.centerYAnchor),
            plusButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            plusButton.widthAnchor.constraint(equalToConstant: 40),
            plusButton.heightAnchor.constraint(equalToConstant: 40),
            
            categoryCollectionView.topAnchor.constraint(equalTo: libraryLabel.bottomAnchor, constant: 15),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 45),
            
            mainCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 10),
            mainCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Logic Data (SỬA ĐỔI QUAN TRỌNG)
    
    private func loadDataFromFirebase() {
        loadingIndicator.startAnimating()
        let group = DispatchGroup()
        
        var fetchedLevels: [LevelData] = []
        
        // 1. Chỉ lấy level từ Firebase
        group.enter()
        FirebaseManager.shared.fetchLevels { levels in
            fetchedLevels = levels
            group.leave()
        }
        
        // 2. Lấy Categories
        group.enter()
        FirebaseManager.shared.fetchCategories { [weak self] fetchedCats in
            if !fetchedCats.isEmpty {
                var mainCats = fetchedCats.filter { $0 != "Others" }.sorted()
                var finalCats = ["All"] + mainCats
                if fetchedCats.contains("Others") { finalCats.append("Others") }
                self?.categories = finalCats
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            self.categoryCollectionView.reloadData()
            
            self.allLevels = fetchedLevels
            self.refreshDataDisplay()
        }
    }
    
    private func refreshDataDisplay() {
        if allLevels.isEmpty { return }
        
        //  Merge với Local Data
        // Duyệt qua từng level lấy từ Firebase
        // Kiểm tra xem trong Local (GameStorageManager) có file save của level này không
        // Nếu có -> Thay thế bằng bản local
        var mergedLevels: [LevelData] = []
        for level in allLevels {
            // Hàm loadLevelProgress sẽ ưu tiên lấy từ file local nếu tồn tại
            // Nếu không có file local, nó trả về chính level Firebase
            let localVer = GameStorageManager.shared.loadLevelProgress(originalLevel: level)
            
            // GIỮ LẠI `createdAt` của Firebase để sắp xếp
            // Vì yêu cầu của bạn là "Hiển thị theo createdAt của Firebase"
            var finalVer = localVer
            finalVer.createdAt = level.createdAt // Reset về thời gian gốc trên server
            
            mergedLevels.append(finalVer)
        }
        
        self.allLevels = mergedLevels
        
        // 1. Gom nhóm theo groupId
        self.allLevelsMap = Dictionary(grouping: allLevels, by: { $0.groupId })
        
        // 2. Tạo danh sách hiển thị
        // Lấy đại diện (Easy) và sắp xếp theo createdAt (của Firebase)
        self.groupedLevels = allLevelsMap.values.compactMap { levels in
            return levels.first(where: { $0.difficulty == 3 }) ?? levels.first
        }.sorted(by: { $0.createdAt > $1.createdAt })
        
        filterLevels()
    }
    
    private func filterLevels() {
        let cat = categories[currentCategoryIndex]
        if cat == "Tất cả" || cat == "All" {
            displayedLevels = groupedLevels
        } else {
            displayedLevels = groupedLevels.filter { $0.category == cat }
        }
        mainCollectionView.reloadData()
    }
    
    // MARK: - Actions: Add Image
    
    // [PLUS BUTTON] -> Firebase (3 cấp độ)
    @objc func didTapAdd() {
        isCreatingFirebaseLevels = true
        let popup = ImportPhotoPopupViewController()
        popup.modalPresentationStyle = .overFullScreen
        popup.delegate = self
        present(popup, animated: false)
    }
    
    // [MIDDLE BUTTON] -> Local (1 cấp độ)
    func handleMiddleButtonTap() {
        isCreatingFirebaseLevels = false
        let popup = ImportPhotoPopupViewController()
        popup.modalPresentationStyle = .overFullScreen
        popup.delegate = self
        present(popup, animated: false)
    }
    
    // Delegate khi chọn ảnh xong
    func didSelectImage(_ image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.onDidCrop = { [weak self] (croppedImage, category) in
            guard let self = self else { return }
            
            if self.isCreatingFirebaseLevels {
                // Logic Plus Button: 3 cấp độ -> Upload Firebase
                self.presentCategorySelectionAndUpload(image: croppedImage)
            } else {
                // Logic Middle Button: 1 cấp độ -> Lưu Local
                self.handleCreateOneLevelToLocal(image: croppedImage, category: category)
            }
        }
        let nav = UINavigationController(rootViewController: cropVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Helper: Chọn Category từ Firebase
    private func presentCategorySelectionAndUpload(image: UIImage) {
        // Hiện loading trong lúc tải danh sách category
        self.loadingIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
        
        FirebaseManager.shared.fetchCategories { [weak self] categories in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            // Tạo ActionSheet để chọn
            let alert = UIAlertController(title: "Chọn Danh Mục", message: "Vui lòng chọn danh mục cho tác phẩm này", preferredStyle: .actionSheet)
            
            // Nếu không tải được hoặc danh sách rỗng, thêm mục mặc định
            let listToShow = categories.isEmpty ? ["Khác", "Động vật", "Phong cảnh"] : categories
            
            for category in listToShow {
                let action = UIAlertAction(title: category, style: .default) { _ in
                    // Người dùng chọn xong -> Tiến hành tạo 3 level và Upload
                    self.handleCreateThreeLevelsToFirebase(image: image, category: category)
                }
                alert.addAction(action)
            }
            
            // Nút Hủy
            let cancelAction = UIAlertAction(title: "Hủy bỏ", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            // Cấu hình cho iPad (tránh crash)
            if let popover = alert.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            self.present(alert, animated: true)
        }
    }
    
    // --- Logic 1: Tạo 3 Level (Firebase) ---
    private func handleCreateThreeLevelsToFirebase(image: UIImage, category: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            // BƯỚC 1: Xử lý thô
            guard let rawData = ImageProcessor.shared.prepareImageData(image: image, targetDimension: 48) else {
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = true
                    self.loadingIndicator.stopAnimating()
                }
                return
            }
            
            let groupId = UUID().uuidString
            let configs = [(1, 10), (2, 20), (3, 30)]
            var levelsToUpload: [LevelData] = []
            
            // BƯỚC 2: Tạo 3 biến thể
            for config in configs {
                let newId = UUID().uuidString
                var newLevel = ImageProcessor.shared.generateLevelFromRawData(
                    rawData: rawData,
                    imageId: newId,
                    groupId: groupId,
                    difficulty: config.0,
                    maxColors: config.1
                )
                newLevel.name = "Pixel Art"
                newLevel.category = category
                newLevel.createdAt = Date()
                levelsToUpload.append(newLevel)
            }
            
            // BƯỚC 3: Upload
            let uploadGroup = DispatchGroup()
            var uploadSuccess = true
            
            for level in levelsToUpload {
                uploadGroup.enter()
                FirebaseManager.shared.uploadLevel(level: level) { success in
                    if !success { uploadSuccess = false }
                    uploadGroup.leave()
                }
            }
            
            uploadGroup.notify(queue: .main) {
                self.view.isUserInteractionEnabled = true
                self.loadingIndicator.stopAnimating()
                
                if uploadSuccess {
                    // Thêm vào danh sách hiện tại để hiển thị ngay
                    self.allLevels.insert(contentsOf: levelsToUpload, at: 0)
                    self.refreshDataDisplay()
                    self.mainCollectionView.setContentOffset(.zero, animated: true)
                } else {
                    let alert = UIAlertController(title: "Lỗi", message: "Lỗi upload server", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // --- Logic 2: Tạo 1 Level (Local - Middle Button) ---
    private func handleCreateOneLevelToLocal(image: UIImage, category: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let rawData = ImageProcessor.shared.prepareImageData(image: image, targetDimension: 48) else { return }
            
            let newId = UUID().uuidString
            let defaultName = "My Art \(Int.random(in: 100...999))"
            
            // Tạo 1 level
            var newLevel = ImageProcessor.shared.generateLevelFromRawData(
                rawData: rawData,
                imageId: newId,
                groupId: newId,
                difficulty: 1,
                maxColors: 10
            )
            
            newLevel.name = defaultName
            newLevel.category = category
            newLevel.isLocked = false
            newLevel.createdAt = Date()
            
            // LƯU THẲNG VÀO LOCAL
            GameStorageManager.shared.saveLevelProgress(newLevel)
            
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                self.loadingIndicator.stopAnimating()
                
                // Chơi luôn
                self.startGame(level: newLevel)
            }
        }
    }
    
    // MARK: - Game & Navigation Logic
    
    private func startGame(level: LevelData) {
        // Load lại progress từ local (nếu có) trước khi vào chơi
        let levelToPlay = GameStorageManager.shared.loadLevelProgress(originalLevel: level)
        let vm = GameViewModel(level: levelToPlay)
        let vc = GameViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        if let topController = self.presentedViewController {
            topController.view.window?.layer.add(transition, forKey: kCATransition)
            topController.present(nav, animated: false)
        } else {
            self.view.window?.layer.add(transition, forKey: kCATransition)
            self.present(nav, animated: false)
        }
    }
    
    // Delegate từ DifficultySelectionViewController
    func didSelectLevelToPlay(_ level: LevelData) {
        startGame(level: level)
    }
    
    // Delegate mở khóa
    func didTapWatchVideo() {
        let alert = UIAlertController(title: "Watching Ad...", message: "Please wait 2 seconds", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            alert.dismiss(animated: true) {
                guard let self = self, let level = self.pendingUnlockLevel else { return }
                GameStorageManager.shared.markLevelAsUnlocked(id: level.id)
                
                // Check xem có anh em không
                if let variants = self.allLevelsMap[level.groupId], variants.count > 1 {
                    self.showDifficultySelection(variants: variants)
                } else {
                    self.startGame(level: level)
                }
                self.pendingUnlockLevel = nil
            }
        }
    }
    func didTapCloseUnlockPopup() { pendingUnlockLevel = nil }
    
    private func showDifficultySelection(variants: [LevelData]) {
        let difficultyVC = DifficultySelectionViewController(levels: variants)
        difficultyVC.delegate = self
        difficultyVC.modalPresentationStyle = .fullScreen
        
        // Tạo animation trượt ngan
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.window?.layer.add(transition, forKey: kCATransition)
        
        present(difficultyVC, animated: false)
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
        cell.configure(level: displayedLevels[indexPath.item], mode: .fullPreview)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            currentCategoryIndex = indexPath.item
            categoryCollectionView.reloadData()
            filterLevels()
        } else {
            // [LOGIC CHỌN LEVEL]
            let representativeLevel = displayedLevels[indexPath.item]
            
            let isUnlocked = GameStorageManager.shared.isLevelUnlocked(id: representativeLevel.id) || !representativeLevel.isLocked
            
            if isUnlocked {
                let groupId = representativeLevel.groupId
                
                // Nếu là Firebase Level (Có nhóm 3 cấp độ)
                if let variants = allLevelsMap[groupId], variants.count > 1 {
                    showDifficultySelection(variants: variants)
                } else {
                    // Nếu là Local Level
                    startGame(level: representativeLevel)
                }
            } else {
                pendingUnlockLevel = representativeLevel
                let vc = UnlockLevelViewController()
                vc.delegate = self
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }
    }
}
