import UIKit
import PhotosUI

// MARK: - Custom Cell cho thanh chọn Background
class BackgroundOptionCell: UICollectionViewCell {
    
    // Biến cờ để biết cell này có cần viền mỏng khi không được chọn hay không
    // (Dùng cho nút Upload và nút Màu Trắng)
    private var isBordered: Bool = false
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#3475CB")
        return iv
    }()
    
    override var isSelected: Bool {
        didSet {
            updateBorder()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(iconView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Shadow cho cell
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // Hàm cập nhật viền dựa trên trạng thái select và loại nút
    private func updateBorder() {
        if isSelected {
            // Đang chọn -> Viền dày màu tím/xanh đậm
            layer.borderWidth = 3
            layer.borderColor = UIColor(hex: "#D958F6").cgColor
        } else {
            // Không chọn
            if isBordered {
                // Nếu là nút Upload/White -> Viền mỏng màu xám/xanh
                layer.borderWidth = 1
                layer.borderColor = UIColor.lightGray.cgColor
            } else {
                // Ảnh thường -> Không viền
                layer.borderWidth = 0
                layer.borderColor = nil
            }
        }
    }
    
    func configure(imageName: String?, isUploadButton: Bool = false, isWhiteButton: Bool = false) {
        // Reset trạng thái
        imageView.image = nil
        iconView.isHidden = true
        
        if isUploadButton {
            isBordered = true
            imageView.backgroundColor = .white
            iconView.image = UIImage(named: "uploadIcon")
            iconView.isHidden = false
            
        } else if isWhiteButton {
            isBordered = true
            imageView.backgroundColor = .white
            
        } else {
            isBordered = false
            // Load ảnh từ Assets
            if let name = imageName {
                imageView.image = UIImage(named: name)
            }
            // Màu nền backup nếu ảnh chưa load kịp (để tránh màu trắng lẫn vào)
            imageView.backgroundColor = UIColor(hex: "#E0E0E0")
        }
        
        updateBorder()
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
    private let fullScreenBackgroundView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
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
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 0, height: 8)
        v.layer.shadowRadius = 15
        v.layer.masksToBounds = false
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
    
    private let continueButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("Continue", for: .normal)
        
        // 1. Font chữ đậm, to, có shadow cho chữ (như ảnh)
        btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .heavy)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        // 2. Màu nền :
        btn.backgroundColor = UIColor(hex: "#4A90E2")
        
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
        view.addSubview(fullScreenBackgroundView)
        fullScreenBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
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
            fullScreenBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            fullScreenBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            fullScreenBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fullScreenBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Container 2:3
            artworkContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            artworkContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            artworkContainer.heightAnchor.constraint(equalTo: artworkContainer.widthAnchor, multiplier: 1.5),
            
            backgroundImageView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            
            // Canvas View: Căn giữa, Rộng 0.8, Tỉ lệ 1:1, Căn dọc 2/3
            canvasView.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            canvasView.centerYAnchor.constraint(equalTo: artworkContainer.centerYAnchor),
            canvasView.widthAnchor.constraint(equalTo: artworkContainer.widthAnchor),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 90)
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
            collectionView.heightAnchor.constraint(equalToConstant: 100)
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
