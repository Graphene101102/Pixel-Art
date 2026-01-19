import UIKit
import PhotosUI

// Class Custom TabBar để tăng chiều cao
class CustomTabBar: UITabBar {
    private let customHeight: CGFloat = 90
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = customHeight + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
        return sizeThatFits
    }
}

class MainTabController: UITabBarController {

    // Nút tròn to ở giữa
    private let middleButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.backgroundColor = UIColor(hex: "#3475CB")
        btn.tintColor = .white
        btn.layer.cornerRadius = 28
        
        // Shadow
        btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        btn.layer.shadowOpacity = 0.4
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Thay thế TabBar mặc định
        setValue(CustomTabBar(), forKey: "tabBar")
        setupTabs()
        setupMiddleButton()
    }
    
    private func setupTabs() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "archivebox.fill"), selectedImage: nil)
        
        let clipboardVC = UIViewController() // Placeholder
        clipboardVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "list.clipboard"), selectedImage: nil)
        
        let placeholderVC = UIViewController()
        placeholderVC.tabBarItem.isEnabled = false
        
        let galleryVC = GalleryViewController()
        let galleryNav = UINavigationController(rootViewController: galleryVC)
        galleryNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "photo"), selectedImage: nil)
        
        let settingsVC = UIViewController() // Placeholder
        settingsVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "gearshape"), selectedImage: nil)

        // Căn chỉnh icon thấp xuống
        let verticalOffset: CGFloat = 38
        let itemInsets = UIEdgeInsets(top: verticalOffset, left: 0, bottom: -verticalOffset, right: 0)
        for item in [homeNav, clipboardVC, galleryNav, settingsVC] {
            item.tabBarItem.imageInsets = itemInsets
        }

        viewControllers = [homeNav, clipboardVC, placeholderVC, galleryNav, settingsVC]
        
        // Style
        tabBar.backgroundColor = .white
        tabBar.tintColor = UIColor(hex: "#3475CB")
        tabBar.unselectedItemTintColor = UIColor(hex: "#828282")
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -4)
        tabBar.layer.shadowRadius = 10
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
    }
    
    private func setupMiddleButton() {
        tabBar.addSubview(middleButton)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            middleButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            middleButton.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 38), // Thấp xuống ngang hàng
            middleButton.widthAnchor.constraint(equalToConstant: 56),
            middleButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        middleButton.addTarget(self, action: #selector(didTapMiddleButton), for: .touchUpInside)
        tabBar.bringSubviewToFront(middleButton)
    }
    
    // MARK: - Action Nút Giữa (LƯU LOCAL)
    @objc private func didTapMiddleButton() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self // MainTab tự xử lý
        present(picker, animated: true)
    }
    
    // Hàm xử lý ảnh Local
    private func handleLocalImport(image: UIImage, name: String, category: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newId = UUID().uuidString
            // Chuyển ảnh thành Level
            if var newLevel = ImageProcessor.shared.processImage(image: image, imageId: newId, targetDimension: 64) {
                newLevel.name = name
                newLevel.category = category
                newLevel.isLocked = false
                
                // CHỈ LƯU LOCAL
                GameStorageManager.shared.saveLevelProgress(newLevel)
                
                DispatchQueue.main.async {
                    self.startGame(level: newLevel)
                }
            }
        }
    }
    
    private func startGame(level: LevelData) {
        let vm = GameViewModel(level: level)
        let vc = GameViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// Delegate chọn ảnh cho MainTab
extension MainTabController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        // Mở màn hình Crop
                        let cropVC = CropViewController(image: uiImage)
                        
                        // Xử lý kết quả: Lưu Local
                        cropVC.onDidCrop = { [weak self] (cropped, name, cat) in
                            self?.handleLocalImport(image: cropped, name: name, category: cat)
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
