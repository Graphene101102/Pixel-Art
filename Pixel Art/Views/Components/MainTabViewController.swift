import UIKit

class CustomTabBar: UITabBar {
    private let customHeight: CGFloat = 60
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = customHeight + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
        return sizeThatFits
    }
}

class MainTabController: UITabBarController, ImportPhotoPopupDelegate {
    
    private let middleButton: UIButton = {
        let btn = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.backgroundColor = UIColor(hex: "#3475CB"); btn.tintColor = .white; btn.layer.cornerRadius = 28
        btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor; btn.layer.shadowOpacity = 0.4; btn.layer.shadowOffset = CGSize(width: 0, height: 3); btn.layer.shadowRadius = 4
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setValue(CustomTabBar(), forKey: "tabBar")
        setupTabs(); setupMiddleButton()
    }
    
    private func setupTabs() {
        let homeVC = HomeViewController(); let homeNav = UINavigationController(rootViewController: homeVC); homeNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "HomeIcon"), selectedImage: nil)
        let clipboardVC = UIViewController(); clipboardVC.view.backgroundColor = .white; clipboardVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "dailyIcon"), selectedImage: nil)
        let placeholderVC = UIViewController(); placeholderVC.tabBarItem.isEnabled = false
        let galleryVC = GalleryViewController(); let galleryNav = UINavigationController(rootViewController: galleryVC); galleryNav.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "galleryIcon"), selectedImage: nil)
        let settingsVC = UIViewController(); settingsVC.view.backgroundColor = .white; settingsVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(named: "settingIcon"), selectedImage: nil)
        
        let itemInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        for item in [homeNav, clipboardVC, galleryNav, settingsVC] { item.tabBarItem.imageInsets = itemInsets }
        
        viewControllers = [homeNav, clipboardVC, placeholderVC, galleryNav, settingsVC]
        tabBar.backgroundColor = .white; tabBar.tintColor = UIColor(hex: "#3475CB"); tabBar.unselectedItemTintColor = UIColor(hex: "#828282")
        tabBar.layer.shadowColor = UIColor.black.cgColor; tabBar.layer.shadowOpacity = 0.05; tabBar.layer.shadowOffset = CGSize(width: 0, height: -2); tabBar.layer.shadowRadius = 5
        tabBar.backgroundImage = UIImage(); tabBar.shadowImage = UIImage()
    }
    
    private func setupMiddleButton() {
        tabBar.addSubview(middleButton); middleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            middleButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor), middleButton.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 6), middleButton.widthAnchor.constraint(equalToConstant: 56), middleButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        middleButton.addTarget(self, action: #selector(didTapMiddleButton), for: .touchUpInside)
        tabBar.bringSubviewToFront(middleButton)
    }
    
    // Action Nút Giữa: Gọi function bên HomeVC để đồng bộ logic
    @objc private func didTapMiddleButton() {
        UIView.animate(withDuration: 0.1, animations: { self.middleButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }) { _ in UIView.animate(withDuration: 0.1) { self.middleButton.transform = .identity } }
        
        // Cách tối ưu: Gọi hàm xử lý popup của HomeVC nếu Home đang hiển thị
        if let nav = selectedViewController as? UINavigationController, let homeVC = nav.viewControllers.first as? HomeViewController {
            homeVC.handleMiddleButtonTap()
        } else {
            // Nếu đang ở tab khác, tự hiện popup và xử lý local import riêng
            let popup = ImportPhotoPopupViewController(); popup.modalPresentationStyle = .overFullScreen; popup.delegate = self
            present(popup, animated: false)
        }
    }
    
    // Delegate (Chỉ dùng khi KHÔNG Ở tab Home)
    func didSelectImage(_ image: UIImage) {
        let cropVC = CropViewController(image: image)
        cropVC.onDidCrop = { [weak self] (croppedImage, category) in
            self?.handleLocalImport(image: croppedImage, category: category)
        }
        let nav = UINavigationController(rootViewController: cropVC); nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    private func handleLocalImport(image: UIImage, category: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            // [FIX LỖI COMPILER] Gọi hàm 2 bước mới
            guard let rawData = ImageProcessor.shared.prepareImageData(image: image, targetDimension: 32) else { return }
            let newId = UUID().uuidString
            let defaultName = "My Art \(Int.random(in: 100...999))"
            
            var newLevel = ImageProcessor.shared.generateLevelFromRawData(
                rawData: rawData,
                imageId: newId,
                groupId: newId,
                difficulty: 1,
                maxColors: 10
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
