import UIKit
import PhotosUI


class HomeViewController: UIViewController {
    
    // MARK: - Data
    private var allLevels: [LevelData] = []
    private var displayedLevels: [LevelData] = []
    
    // Danh mục (Mặc định)
    private var categories: [String] = ["Tất cả"]
    private var currentCategoryIndex = 0
    
    // MARK: - UI Elements
    
    // 1. Background
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    // 2. Header
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
    
    // 3. Category & Main Grid
    private var categoryCollectionView: UICollectionView!
    private var mainCollectionView: UICollectionView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // 4. Bottom Bar (Khung trắng)
    private let bottomBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        // Shadow nhẹ lên trên
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset = CGSize(width: 0, height: -4)
        v.layer.shadowRadius = 10
        return v
    }()
    
    // 5. Nút Cộng (Sửa lại style: Bỏ viền, vẫn giữ bo tròn)
    private let plusButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        
        btn.backgroundColor = UIColor(hex: "#3475CB")
        btn.tintColor = .white
        
        // Bo tròn (Size 52 -> Radius 26)
        btn.layer.cornerRadius = 26
        
        // [ĐÃ SỬA] Bỏ viền trắng
        btn.layer.borderWidth = 0
        
        // Shadow nút
        btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // Background
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        [libraryLabel, topicLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup Category CV
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
        
        // Setup Main Grid
        let mainLayout = UICollectionViewFlowLayout()
        let padding: CGFloat = 17
        let availableWidth = view.frame.width - (padding * 2) - 10
        let itemWidth = availableWidth / 2
        let itemHeight = itemWidth + 40
        
        mainLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        mainLayout.minimumLineSpacing = 20
        mainLayout.sectionInset = UIEdgeInsets(top: 10, left: padding, bottom: 100, right: padding)
        
        mainCollectionView = UICollectionView(frame: .zero, collectionViewLayout: mainLayout)
        mainCollectionView.backgroundColor = .clear
        mainCollectionView.register(LevelListCell.self, forCellWithReuseIdentifier: "LevelListCell")
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainCollectionView)
        
        // Setup Bottom Bar
        setupBottomBar()
        
        loadingIndicator.center = view.center
        view.addSubview(loadingIndicator)
        
        // Constraints
        NSLayoutConstraint.activate([
            libraryLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            libraryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
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
    
    // --- Bottom Bar Logic ---
    private func setupBottomBar() {
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBarView)
        
        NSLayoutConstraint.activate([
            bottomBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // Height = 70 + SafeArea (để đảm bảo phần nội dung cao khoảng 70-80px)
            bottomBarView.heightAnchor.constraint(equalToConstant: 80 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 20))
        ])
        
        // Cấu hình Nút Plus (để add vào stack)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.widthAnchor.constraint(equalToConstant: 52).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        plusButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        setupBottomIcons()
    }
    
    private func setupBottomIcons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing // Chia đều khoảng cách
        stackView.alignment = .center // [QUAN TRỌNG] Căn giữa theo chiều dọc
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBarView.addSubview(stackView)
        
        // Item 1: Library
        stackView.addArrangedSubview(createBottomBarItem(iconName: "archivebox.fill", isActive: true))
        
        // Item 2: Clipboard
        stackView.addArrangedSubview(createBottomBarItem(iconName: "list.clipboard", isActive: false))
        
        // Item 3: Nút Plus (Nằm cùng hàng)
        stackView.addArrangedSubview(plusButton)
        
        // Item 4: Gallery
        stackView.addArrangedSubview(createBottomBarItem(iconName: "photo", isActive: false))
        
        // Item 5: Settings
        stackView.addArrangedSubview(createBottomBarItem(iconName: "gearshape", isActive: false))
        
        // Constraints StackView
        NSLayoutConstraint.activate([
            // Căn StackView vào phần trên của BottomBar (phần màu trắng chứa nội dung)
            stackView.topAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -30),
            // Chiều cao stack đủ để chứa nút to nhất (PlusButton 52px)
            stackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func createBottomBarItem(iconName: String, isActive: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 40).isActive = true
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let activeColor = UIColor(hex: "#3475CB")
        let inactiveColor = UIColor(hex: "#828282")
        iconView.tintColor = isActive ? activeColor : inactiveColor
        container.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            // Nếu Active thì nhích lên 1 xíu để nhường chỗ cho dot
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: isActive ? -6 : 0),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        if isActive {
            let dot = UIView()
            dot.backgroundColor = activeColor
            dot.layer.cornerRadius = 3
            dot.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                dot.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
                dot.widthAnchor.constraint(equalToConstant: 6),
                dot.heightAnchor.constraint(equalToConstant: 6)
            ])
        }
        return container
    }
    
    //  MARK: - Data Loading Logic
    private func loadData() {
        loadingIndicator.startAnimating()
        let group = DispatchGroup()
        
        // 1. Tải Levels
        group.enter()
        FirebaseManager.shared.fetchLevels { [weak self] levels in
            self?.allLevels = levels
            group.leave()
        }
        
        // 2. Tải Categories
        group.enter()
        FirebaseManager.shared.fetchCategories { [weak self] fetchedCats in
            // Logic sắp xếp: [Tất cả] -> [A, B, C...] -> [Khác]
            if !fetchedCats.isEmpty {
                let otherKey = "Others"
                
                // Lọc bỏ "Khác" ra khỏi danh sách tải về (nếu có)
                var mainCats = fetchedCats.filter { $0 != otherKey }
                mainCats.sort() // Sắp xếp Alphabet
                
                // Ghép lại: [Tất cả] + [Danh mục thường] + [Khác]
                var finalCats = ["Tất cả"] + mainCats
                
                // Nếu trong Firebase có "Khác", hoặc muốn luôn luôn hiện "Khác"
                // Kiểm tra xem Firebase có chứa "Khác" không để thêm vào cuối
                if fetchedCats.contains(otherKey) {
                    finalCats.append(otherKey)
                }
                
                self?.categories = finalCats
                
            } else {
                // Fallback (Mặc định Khác luôn ở cuối)
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
    
    private func filterLevels() {
        let selectedCategoryName = categories[currentCategoryIndex]
        
        if selectedCategoryName == "All" || selectedCategoryName == "Tất cả" {
            displayedLevels = allLevels
        } else {
            displayedLevels = allLevels.filter { $0.category == selectedCategoryName }
        }
        mainCollectionView.reloadData()
    }
    
    //  MARK: -  Actions
    @objc private func didTapAdd() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCropScreen(with image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.onDidCrop = { [weak self] (croppedImage, name, category) in
            self?.processAndUpload(image: croppedImage, name: name, category: category)
        }
        navigationController?.pushViewController(cropVC, animated: true)
    }
    
    private func processAndUpload(image: UIImage, name: String, category: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.global(qos: .userInitiated).async {
            if var newLevel = ImageProcessor.shared.processImage(image: image, targetDimension: 64) {
                newLevel.name = name
                newLevel.category = category
                FirebaseManager.shared.uploadLevel(level: newLevel) { [weak self] success in
                    DispatchQueue.main.async {
                        self?.view.isUserInteractionEnabled = true
                        if success { self?.loadData() }
                        else { self?.loadingIndicator.stopAnimating() }
                    }
                }
            }
        }
    }
}

//  MARK: -  Extensions CollectionView
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView { return categories.count }
        return displayedLevels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
            let isSelected = indexPath.item == currentCategoryIndex
            cell.configure(text: categories[indexPath.item], isSelected: isSelected)
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
            let level = displayedLevels[indexPath.item]
            let viewModel = GameViewModel(level: level)
            let gameVC = GameViewController(viewModel: viewModel)
            let navWrapper = UINavigationController(rootViewController: gameVC)
            navWrapper.modalPresentationStyle = .fullScreen
            present(navWrapper, animated: true)
        }
    }
}

//  MARK: -  Cell Classes
class CategoryCell: UICollectionViewCell {
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 15
        contentView.layer.borderWidth = 1
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(text: String, isSelected: Bool) {
        label.text = text
        if isSelected {
            contentView.backgroundColor = UIColor(hex: "#3475CB")
            contentView.layer.borderColor = UIColor(hex: "#3475CB").cgColor
            label.textColor = .white
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
            label.textColor = UIColor(hex: "#828282")
        }
    }
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: 35)
        let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required)
        attributes.frame.size = size
        return attributes
    }
}

// Extension PHPicker
extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async { self?.presentCropScreen(with: uiImage) }
                }
            }
        }
    }
}
