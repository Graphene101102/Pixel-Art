import UIKit

// 1. Giữ nguyên CustomTabBar
class CustomTabBar: UITabBar {
    private var contentHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 90 : 60
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        if let window = UIApplication.shared.windows.first {
            sizeThatFits.height = contentHeight + window.safeAreaInsets.bottom
        } else {
            sizeThatFits.height = contentHeight
        }
        return sizeThatFits
    }
}

class MainTabController: UITabBarController, ImportPhotoPopupDelegate {
    
    private let middleButton: UIButton = {
        let btn = UIButton(type: .custom)
        
        // Icon to hơn trên iPad
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let config = UIImage.SymbolConfiguration(pointSize: isPad ? 30 : 22, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        
        btn.backgroundColor = UIColor(hex: "#0097FF")
        btn.tintColor = .white
        
        // Shadow
        btn.layer.shadowColor = UIColor(hex: "#0097FF").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Thay TabBar
        setValue(CustomTabBar(), forKey: "tabBar")
        
        // 2. Setup
        setupTabs()
        setupAppearance()
        setupMiddleButton()
        
        // Chỉ áp dụng cho iOS 17 trở lên, các bản cũ hơn thường mặc định nằm dưới
        if #available(iOS 17.0, *) {
            self.traitOverrides.horizontalSizeClass = .compact
        }
    }
    
    // Đảm bảo nút luôn nổi lên trên
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(middleButton)
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.systemGray2
        itemAppearance.selected.iconColor = UIColor(hex: "#0097FF")
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        tabBar.layer.shadowRadius = 8
    }
    
    private func setupTabs() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "HomeIcon"), selectedImage: nil)
        
        let clipboardVC = UIViewController()
        clipboardVC.view.backgroundColor = .white
        clipboardVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "dailyIcon"), selectedImage: nil)
        
        let placeholderVC = UIViewController()
        placeholderVC.tabBarItem.isEnabled = false
        
        let galleryVC = GalleryViewController()
        let galleryNav = UINavigationController(rootViewController: galleryVC)
        galleryNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "galleryIcon"), selectedImage: nil)
        
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "settingIcon"), selectedImage: nil)
        
        // Căn giữa icon cho iPhone
        if UIDevice.current.userInterfaceIdiom != .pad {
            let itemInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            [homeNav, clipboardVC, galleryNav, settingsNav].forEach {
                $0.tabBarItem.imageInsets = itemInsets
            }
        }
        
        viewControllers = [homeNav, clipboardVC, placeholderVC, galleryNav, settingsNav]
    }
    
    private func setupMiddleButton() {
        // Thêm vào view chính
        view.addSubview(middleButton)
        middleButton.translatesAutoresizingMaskIntoConstraints = false
        
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // Kích thước nút: iPad 70, iPhone 48
        let buttonSize: CGFloat = isPad ? 65 : 42
        
        // Chiều cao nội dung TabBar (phải khớp CustomTabBar)
        let contentHeight: CGFloat = isPad ? 90 : 60
        
        // Tính khoảng cách để nút nằm giữa TabBar
        // (Chiều cao TabBar - Chiều cao Nút) / 2
        var bottomSpace = (contentHeight - buttonSize) / 2
        
        if !isPad {
            bottomSpace -= 6
        }
        
        middleButton.layer.cornerRadius = buttonSize / 2
        
        NSLayoutConstraint.activate([
            // 1. Căn giữa màn hình
            middleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 2. [QUAN TRỌNG] Neo vào Safe Area Bottom (thay vì TabBar) để tránh lỗi
            // Đẩy lên trên một khoảng bằng bottomSpace
            middleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomSpace),
            
            // 3. Kích thước
            middleButton.widthAnchor.constraint(equalToConstant: buttonSize),
            middleButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        middleButton.addTarget(self, action: #selector(didTapMiddleButton), for: .touchUpInside)
    }
    
    // MARK: - Actions & Logic
    @objc private func didTapMiddleButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.middleButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.middleButton.transform = .identity
            }
        }
        
        if let nav = selectedViewController as? UINavigationController, let homeVC = nav.viewControllers.first as? HomeViewController {
            homeVC.handleMiddleButtonTap()
        } else {
            let popup = ImportPhotoPopupViewController()
            popup.modalPresentationStyle = .overFullScreen
            popup.delegate = self
            present(popup, animated: false)
        }
    }
    
    func didSelectImage(_ image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.onDidCrop = { [weak self] (croppedImage, category) in
            self?.handleLocalImport(image: croppedImage, category: category)
        }
        let nav = UINavigationController(rootViewController: cropVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func handleLocalImport(image: UIImage, category: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let rawData = ImageProcessor.shared.prepareImageData(image: image, targetDimension: 32) else { return }
            let newId = UUID().uuidString
            let defaultName = "My Art \(Int.random(in: 100...999))"
            
            var newLevel = ImageProcessor.shared.generateLevelFromRawData(
                rawData: rawData, imageId: newId, groupId: newId, difficulty: 1, maxColors: 10
            )
            
            newLevel.name = defaultName; newLevel.category = category; newLevel.isLocked = false; newLevel.createdAt = Date()
            GameStorageManager.shared.saveLevelProgress(newLevel)
            
            DispatchQueue.main.async {
                let vm = GameViewModel(level: newLevel)
                let vc = GameViewController(viewModel: vm)
                let nav = UINavigationController(rootViewController: vc); nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
        }
    }
}
