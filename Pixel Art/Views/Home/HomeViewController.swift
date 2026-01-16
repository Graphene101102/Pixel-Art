import UIKit
import PhotosUI

class HomeViewController: UIViewController {
    
    private var levels: [LevelData] = []
    private var collectionView: UICollectionView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLevels()
    }
    
    private func setupUI() {
        title = "Thư viện Pixel"
        view.backgroundColor = .systemGroupedBackground
        
        // Nút thêm (+)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        // CollectionView setup
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 16
        let availableWidth = view.frame.width - (padding * 3)
        let itemWidth = availableWidth / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 50)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(LevelListCell.self, forCellWithReuseIdentifier: "LevelListCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        
        // Loading Indicator
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func loadLevels() {
        loadingIndicator.startAnimating()
        FirebaseManager.shared.fetchLevels { [weak self] fetchedLevels in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.levels = fetchedLevels
                self?.collectionView.reloadData()
            }
        }
    }
    
    // --- Actions ---
    
    @objc private func didTapAdd() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    //Mở màn hình crop
    private func presentCropScreen(with image: UIImage) {
        let cropVC = CropViewController(image: image)
        
        // Xử lý callback khi người dùng bấm "Tạo Pixel Art" bên màn hình kia
        cropVC.onDidCrop = { [weak self] (croppedImage, name) in
            self?.processAndUpload(image: croppedImage, name: name)
        }
        
        // Push vào Navigation Controller
        navigationController?.pushViewController(cropVC, animated: true)
    }
    
    private func processAndUpload(image: UIImage, name: String) {
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false // Chặn thao tác
        
        DispatchQueue.global(qos: .userInitiated).async {
            if var newLevel = ImageProcessor.shared.processImage(image: image, targetDimension: 64) {
                newLevel.name = name
                
                FirebaseManager.shared.uploadLevel(level: newLevel) { [weak self] success in
                    DispatchQueue.main.async {
                        self?.view.isUserInteractionEnabled = true
                        if success {
                            self?.loadLevels() // Reload list
                        } else {
                            self?.loadingIndicator.stopAnimating()
                        }
                    }
                }
            }
        }
    }
}

// --- Extensions ---

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return levels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelListCell", for: indexPath) as! LevelListCell
        cell.configure(level: levels[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = levels[indexPath.item]
        let viewModel = GameViewModel(level: level)
        let gameVC = GameViewController(viewModel: viewModel)
        
        let navWrapper = UINavigationController(rootViewController: gameVC)
        navWrapper.modalPresentationStyle = .fullScreen
        
        // Cấu hình kiểu hiển thị Full màn hình
        navWrapper.modalPresentationStyle = .fullScreen
        navWrapper.modalTransitionStyle = .coverVertical // Hoặc .crossDissolve
        
        present(navWrapper, animated: true)
        
        // Push navigation (để có nút back tự động)
        //        navigationController?.pushViewController(gameVC, animated: true)
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
                        self?.presentCropScreen(with: uiImage)
                    }
                }
            }
        }
    }
    
    
    
}
