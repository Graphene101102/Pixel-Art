import UIKit
import PhotosUI

// MARK: - Custom Cell cho thanh chọn Background
class BackgroundOptionCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    
    // 1. Ảnh nền (Cho các cell màu/ảnh)
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()
    
    // 2. Container riêng cho nút Upload (Cái ô vuông nhỏ ở giữa)
    private let uploadInnerContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 12 // Bo góc vuông nhỏ
        
        // Viền xanh dương nhạt cho ô vuông
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor(hex: "#3475CB").cgColor
        
        // Đổ bóng cho ô vuông này (như ảnh)
        v.layer.shadowColor = UIColor(hex: "#3475CB").withAlphaComponent(0.5).cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 2, height: 4)
        v.layer.shadowRadius = 4
        
        return v
    }()
    
    // 3. Icon (Dùng chung cho cả Upload và nút White, nhưng vị trí khác nhau)
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#3475CB")
        return iv
    }()
    
    // Biến cờ
    private var isUploadType: Bool = false
    private var isWhiteType: Bool = false
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        // Cell gốc bo góc
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        layer.cornerRadius = 12
        layer.masksToBounds = false // Để hiện shadow của cell chính (nếu cần khi selected)
        
        // Add Subviews
        contentView.addSubview(imageView)
        contentView.addSubview(uploadInnerContainer)
        
        // Icon nằm trong uploadContainer (nếu là upload) hoặc nằm đè lên image (nếu là white)
        // Để linh hoạt, ta add icon vào contentView, sau đó chỉnh constraint
        contentView.addSubview(iconView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        uploadInnerContainer.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints cố định
        NSLayoutConstraint.activate([
            // ImageView full cell
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Upload Inner Container (Ô vuông nhỏ ở giữa)
            // Kích thước khoảng 60% cell
            uploadInnerContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            uploadInnerContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            uploadInnerContainer.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            uploadInnerContainer.heightAnchor.constraint(equalTo: uploadInnerContainer.widthAnchor),
            
            // Icon view (Sẽ chỉnh constraint động tùy loại)
        ])
    }
    
    // MARK: - Logic Update
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    func configure(imageName: String?, isUploadButton: Bool = false, isWhiteButton: Bool = false) {
        self.isUploadType = isUploadButton
        self.isWhiteType = isWhiteButton
        
        // Reset UI
        imageView.image = nil
        iconView.isHidden = true
        uploadInnerContainer.isHidden = true
        imageView.backgroundColor = UIColor(hex: "#E0E0E0") // Màu nền mặc định
        
        // Remove cũ constraints của icon
        iconView.constraints.forEach { if $0.firstAttribute == .centerX || $0.firstAttribute == .centerY { removeConstraint($0) } }
        iconView.superview?.constraints.forEach {
             if $0.firstItem as? NSObject == iconView || $0.secondItem as? NSObject == iconView {
                 iconView.superview?.removeConstraint($0)
             }
        }
        
        if isUploadButton {
            // --- Cấu hình nút UPLOAD ---
            imageView.isHidden = true // Ẩn nền chính, dùng nền trắng của cell
            contentView.backgroundColor = .white
            
            uploadInnerContainer.isHidden = false // Hiện ô vuông nhỏ
            
            iconView.isHidden = false
            iconView.image = UIImage(named: "uploadIcon") ?? UIImage(systemName: "arrow.up")
            
            // Icon nằm giữa ô vuông nhỏ
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: uploadInnerContainer.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: uploadInnerContainer.centerYAnchor),
                iconView.widthAnchor.constraint(equalTo: uploadInnerContainer.widthAnchor, multiplier: 0.4),
                iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
            ])
            
        } else if isWhiteButton {
            // --- Cấu hình nút MÀU TRẮNG ---
            imageView.isHidden = false
            imageView.backgroundColor = .white
            
            // Có thể thêm icon check hoặc để trống tùy ý
            iconView.isHidden = true
            
        } else {
            // --- Cấu hình ẢNH NỀN ---
            imageView.isHidden = false
            if let name = imageName {
                imageView.image = UIImage(named: name)
            }
        }
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            // === ĐANG CHỌN ===
            // Viền dày màu Tím/Xanh đậm bao quanh toàn bộ Cell
            layer.borderWidth = 3
            layer.borderColor = UIColor(hex: "#D958F6").cgColor // Màu tím như ảnh mẫu upload
            
            // Có thể thêm shadow nhẹ cho cả cell khi đang chọn (tùy thích)
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 4
            
        } else {
            // === KHÔNG CHỌN ===
            layer.borderWidth = 0 // Xóa viền
            layer.borderColor = nil
            
            // [YÊU CẦU] Xóa shadow khi không chọn
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
            layer.shadowOffset = .zero
            
            // Ngoại lệ: Nếu là nút Upload, ô vuông bên trong nó vẫn có shadow (đã set ở phần init của uploadInnerContainer)
            // Nếu là nút White, có thể thêm viền mỏng nhẹ để không bị chìm vào nền trắng
            if isWhiteType {
                layer.borderWidth = 1
                layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            }
        }
    }
}

// MARK: - LevelCompletedViewController
class LevelCompletedViewController: UIViewController {
    
    private let level: LevelData
    
    // Danh sách tên ảnh trong Assets
    // Index 0: Nút Upload
    // Index 1: Nút White ("white")
    // Index 2+: Các ảnh BG
    private var backgroundImages: [String] = ["upload_placeholder", "white", "bg-01", "bg-02", "bg-03", "bg-04", "bg-05", "bg-06", "bg-07", "bg-08", "bg-09"]
    
    private var selectedImage: UIImage?
    private var selectedIndex: Int = 1
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "SELECT BACKGROUND"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        btn.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        return btn
    }()
    
    // Container chứa tranh (Tỉ lệ 2:3)
    private let artworkContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        
        // 1. Viền Trắng Dày
        v.layer.borderWidth = 6
        v.layer.borderColor = UIColor.white.cgColor
        
        // 2. Đổ bóng mềm
        v.layer.shadowColor = UIColor(hex: "##0037FF").cgColor
        v.layer.shadowOpacity = 0.35
        v.layer.shadowOffset = CGSize(width: 10, height: 15)
        v.layer.shadowRadius = 15
        
        v.clipsToBounds = false
        
        return v
    }()
    
    // Ảnh nền phía sau Pixel Art
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        return iv
    }()
    
    // Pixel Art
    private let canvasView = CanvasView()
    
    // CollectionView chọn nền
    private var collectionView: UICollectionView!
    
    private let continueButton: GradientButton = {
        
        let btn = GradientButton(colors: [
            UIColor(hex: "#27A7FF"),
            UIColor(hex: "#47B4FF"),
            UIColor(hex: "#039AFF")
        ])
        btn.setTitle("Continue", for: .normal)
        
        // 1. Font chữ đậm, to, có shadow cho chữ (như ảnh)
        btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .heavy)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        // 3. Bo góc tròn
        btn.layer.cornerRadius = 16
        
        // 4. Viền trắng dày
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        
        // 5. Shadow cho nút
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        
        return btn
    }()
    
    // MARK: - Init
    init(level: LevelData) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupCollectionView()
        
        // Render Pixel Art (Nền trong suốt)
        canvasView.backgroundColor = .clear
        
        let savedLevel = GameStorageManager.shared.loadLevelProgress(originalLevel: self.level)
        canvasView.render(level: savedLevel, currentNumber: -2)
        
        // Mặc định chọn nền Trắng (index 1)
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = .white
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        let bgView = AppBackgroundView()
        view.addSubview(bgView)
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(bgView)
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(artworkContainer)
        
        artworkContainer.addSubview(backgroundImageView)
        artworkContainer.addSubview(canvasView)
        
        view.addSubview(continueButton)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        artworkContainer.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Container 2:3
            artworkContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            artworkContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65),
            artworkContainer.heightAnchor.constraint(equalTo: artworkContainer.widthAnchor, multiplier: 1.5),
            
            backgroundImageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            
            // Canvas View: Căn giữa, Rộng 0.8, Tỉ lệ 1:1, Căn dọc 2/3
            canvasView.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            canvasView.centerYAnchor.constraint(equalTo: artworkContainer.centerYAnchor),
            canvasView.widthAnchor.constraint(equalTo: artworkContainer.widthAnchor, multiplier: 0.95),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        backgroundImageView.layer.cornerRadius = 24
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 90, height: 115)
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BackgroundOptionCell.self, forCellWithReuseIdentifier: "BGCell")
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -30),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 130)
        ])
        
        // Mặc định chọn item thứ 2 (white)
        if backgroundImages.count > 1 {
            let indexPath = IndexPath(item: 1, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        }
    }
    
    // MARK: - Actions
    @objc private func didTapClose() {
        self.dismiss(animated: true, completion: nil)
    }

@objc private func didTapContinue() {
    // 1. Chụp ảnh kết quả (Bao gồm Background + Canvas)
    let renderer = UIGraphicsImageRenderer(bounds: artworkContainer.bounds)
    let capturedImage = renderer.image { context in
        artworkContainer.drawHierarchy(in: artworkContainer.bounds, afterScreenUpdates: true)
    }
    
    // 2. Tính toán thống kê
    // Lấy thời gian đã lưu trong local
    let savedLevel = GameStorageManager.shared.loadLevelProgress(originalLevel: self.level)
    let timeSpent = savedLevel.timeSpent
    
    // Đếm số pixels có màu
    let totalPixels = savedLevel.pixels.filter { $0.number > 0 }.count
    
    // 3. Chuyển sang màn hình Success
    let successVC = SuccessViewController(image: capturedImage, timeSpent: timeSpent, totalPixels: totalPixels)
    successVC.modalPresentationStyle = .fullScreen
    successVC.modalTransitionStyle = .crossDissolve
    present(successVC, animated: true)
}
}

// MARK: - CollectionView Delegate & DataSource
extension LevelCompletedViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgroundImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BGCell", for: indexPath) as! BackgroundOptionCell
        let option = backgroundImages[indexPath.item]
        
        if indexPath.item == 0 {
            // Nút Upload
            cell.configure(imageName: nil, isUploadButton: true)
        } else if option == "white" {
            // Nút Trắng
            cell.configure(imageName: nil, isWhiteButton: true)
        } else {
            // Ảnh BG
            cell.configure(imageName: option)
        }
        
        cell.isSelected = (selectedIndex == indexPath.item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let option = backgroundImages[indexPath.item]
        
        if indexPath.item == 0 {
            // Nút Upload
            openPhotoLibrary()
        } else if option == "white" {
            // Nút Trắng
            selectedIndex = indexPath.item
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = .white
            selectedImage = nil
        } else {
            // Ảnh BG
            selectedIndex = indexPath.item
            backgroundImageView.image = UIImage(named: option)
            selectedImage = nil
        }
    }
    
    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - Helper Class: Gradient Button
    class GradientButton: UIButton {
        private let gradientLayer = CAGradientLayer()
        
        init(colors: [UIColor]) {
            super.init(frame: .zero)
            // Cấu hình Gradient
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = bounds
            gradientLayer.cornerRadius = layer.cornerRadius
        }
    }
}

// MARK: - Photo Picker Delegate
extension LevelCompletedViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let item = results.first else { return }
        
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let self = self, let uiImage = image as? UIImage else { return }
                
                DispatchQueue.main.async {
                    self.selectedImage = uiImage
                    self.backgroundImageView.image = uiImage
                    self.selectedIndex = 0
                    self.collectionView.reloadData()
                    self.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .left)
                }
            }
        }
    }
}
