import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - UI Elements
    
    // 1. Ảnh nền (Full màn hình)
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        // Đảm bảo bạn đã thêm ảnh "splash.pdf" vào Assets và đặt tên là "splash"
        iv.image = UIImage(named: "splash")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    // 2. Logo (Ở giữa phía trên)
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        // Đảm bảo bạn đã thêm ảnh "logo.pdf" vào Assets và đặt tên là "logo"
        iv.image = UIImage(named: "logo")
        iv.contentMode = .scaleAspectFit
        // Bo góc cho logo giống thiết kế
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        return iv
    }()
    
    // 3. Tiêu đề "PIXEL ART" (Màu xanh, viền trắng, Font đậm)
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        
        // Tạo hiệu ứng chữ xanh viền trắng
        let text = "PIXEL ART"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .black), // Dùng font đậm nhất
            .foregroundColor: UIColor(hex: "#0099FF"), // Màu xanh dương
            .strokeColor: UIColor.white,
            .strokeWidth: -4.0 // Số âm để vẽ cả viền và màu bên trong
        ]
        lbl.attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Shadow nhẹ cho chữ nổi khối
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowOffset = CGSize(width: 2, height: 2)
        lbl.layer.shadowOpacity = 0.3
        lbl.layer.shadowRadius = 2
        
        return lbl
    }()
    
    // 4. Phụ đề "COLOR BY NUMBER"
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "COLOR BY NUMBER"
        // Dùng font monospaced để tạo cảm giác pixel
        lbl.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        lbl.textColor = UIColor(hex: "#0099FF")
        lbl.textAlignment = .center
        
        // Viền trắng nhẹ cho dễ đọc
        lbl.layer.shadowColor = UIColor.white.cgColor
        lbl.layer.shadowOffset = CGSize(width: 0, height: 0)
        lbl.layer.shadowOpacity = 1.0
        lbl.layer.shadowRadius = 2
        return lbl
    }()
    
    // 5. Chữ "Loading..."
    private let loadingLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Loading..."
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        lbl.textColor = .black
        lbl.textAlignment = .center
        return lbl
    }()
    
    // 6. Disclaimer "This action may contain ads"
    private let disclaimerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "This action may contain ads"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = .darkGray
        lbl.textAlignment = .center
        return lbl
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Load Data từ firebase
        fetchDataAndTransition()
    }
    
    // MARK: - Logic Load Data
    private func fetchDataAndTransition() {
        // DispatchGroup giúp quản lý nhiều tác vụ bất đồng bộ
        let group = DispatchGroup()
        
        // 1. Tải Levels
        group.enter()
        FirebaseManager.shared.fetchLevels { levels in
            AppData.shared.preloadedLevels = levels
            group.leave() // Báo hiệu xong task 1
        }
        
        // 2. Tải Categories
        group.enter()
        FirebaseManager.shared.fetchCategories { cats in
            if !cats.isEmpty {
                // Logic sắp xếp giống hệt HomeView cũ
                let otherKey = "Others"
                var mainCats = cats.filter { $0 != otherKey }
                mainCats.sort()
                var finalCats = ["Tất cả"] + mainCats
                if cats.contains(otherKey) { finalCats.append(otherKey) }
                AppData.shared.preloadedCategories = finalCats
            } else {
                // Fallback nếu lỗi
                AppData.shared.preloadedCategories = ["Tất cả", "Động vật", "Đồ ăn", "Phong cảnh", "Nhân vật", "Khác"]
            }
            group.leave() // Báo hiệu xong task 2
        }
        
        // 3. (Tùy chọn) Đợi tối thiểu 2 giây để người dùng kịp nhìn thấy Logo đẹp
        // Nếu mạng quá nhanh, splash nháy cái rồi tắt sẽ rất khó chịu.
        group.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            group.leave()
        }
        
        // 4. Khi TẤT CẢ đã xong -> Chuyển màn hình
        group.notify(queue: .main) { [weak self] in
            AppData.shared.hasDataLoaded = true
            self?.transitionToMainApp()
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // Thêm background trước
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Thêm các view còn lại
        [logoImageView, titleLabel, subtitleLabel, loadingLabel, disclaimerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // 1. Logo: Nằm phía trên tâm màn hình một chút
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100), // Dịch lên trên 100pt
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // 2. Title "PIXEL ART": Ngay dưới logo
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 3. Subtitle: Dưới Title
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 4. Disclaimer: Nằm sát đáy màn hình (cách bottom safe area)
            disclaimerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            disclaimerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 5. Loading: Nằm trên Disclaimer
            loadingLabel.bottomAnchor.constraint(equalTo: disclaimerLabel.topAnchor, constant: -10),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Navigation
    private func transitionToMainApp() {
        // Tạo MainTabController
        let mainTabVC = MainTabController()
        mainTabVC.modalTransitionStyle = .crossDissolve
        mainTabVC.modalPresentationStyle = .fullScreen
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = mainTabVC
            }, completion: nil)
        }
    }
}
