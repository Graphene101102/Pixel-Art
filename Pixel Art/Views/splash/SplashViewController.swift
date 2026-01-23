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
    private let titleContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let outlineLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        let text = "PIXEL ART"
        // Font: Đảm bảo dùng đúng tên font pixel bạn đã thêm vào dự án
        let font = UIFont(name: "PixelifySans-Bold", size: 40) ?? UIFont.systemFont(ofSize: 40, weight: .black)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            // Màu stroke là TRẮNG
            .strokeColor: UIColor.white,
            // Màu fill là TRONG SUỐT (để chỉ hiện viền)
            .foregroundColor: UIColor.clear,
            // Độ dày viền trắng: Rất dày (ví dụ: -12) để tạo bao tống
            .strokeWidth: -12.0
        ]
        lbl.attributedText = NSAttributedString(string: text, attributes: attributes)
        return lbl
    }()
    private let foregroundLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        let text = "PIXEL ART"
        // Font phải y hệt lớp nền
        let font = UIFont(name: "PixelifySans-Bold", size: 40) ?? UIFont.systemFont(ofSize: 40, weight: .black)
        let blueColor = UIColor(hex: "#0099FF") // Màu xanh dương
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            // Màu fill là XANH
            .foregroundColor: blueColor,
            // KỸ THUẬT FAKE BOLD: Thêm viền cùng màu XANH để làm chữ mập lên
            .strokeColor: blueColor,
            // Độ dày vừa phải (ví dụ: -5) để làm chữ đậm hơn nét gốc
            .strokeWidth: -5.0
        ]
        lbl.attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Tạo Shadow khối đen cứng (Hard Shadow) giống pixel art
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowOffset = CGSize(width: 4, height: 4) // Đổ bóng xuống dưới phải
        lbl.layer.shadowOpacity = 0.5
        lbl.layer.shadowRadius = 0 // Radius = 0 để bóng sắc nét, không bị nhòe
        
        return lbl
    }()
    
    // 4. Phụ đề "COLOR BY NUMBER"
    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "COLOR BY NUMBER"
        // Dùng font monospaced để tạo cảm giác pixel
        lbl.font =  UIFont(name: "PixelifySans-Medium", size: 18) ?? UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
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
        let text = "Loading..."
        let font = UIFont(name: "PixelifySans-Medium", size: 24) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        
        // Tạo viền trắng xung quanh chữ
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .strokeColor: UIColor.white,
            .strokeWidth: -4.0
        ]
        lbl.attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Đổ bóng cho chữ
        lbl.layer.shadowColor = UIColor.black.cgColor
        lbl.layer.shadowOffset = CGSize(width: 2, height: 2)
        lbl.layer.shadowOpacity = 0.3
        lbl.layer.shadowRadius = 0
        
        return lbl
    }()
    
    // 6. Thanh Loading Bar
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = .clear // Để trong suốt để hiện nền trắng của container
        pv.progressTintColor = UIColor(hex: "#27A7FF") // Màu xanh
        
        // Bo góc thanh chạy bên trong
        pv.layer.cornerRadius = 12
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    // 7. Disclaimer "This action may contain ads"
    private let disclaimerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "This action may contain ads"
        lbl.font = UIFont(name: "PixelifySans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .regular)
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
        
        // --- GIẢ LẬP LOADING PROGRESS ---
        var progress: Float = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            
            // Tăng progress từ từ
            progress += 0.02 // Mỗi 0.05s tăng 2%
            self.progressView.setProgress(progress, animated: true)
            
            // Nếu chạy đến 90% mà chưa xong data thì dừng chờ
            if progress >= 0.9 {
                t.invalidate()
            }
        }
        
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
        
        // 3. Đợi tối thiểu 2.5 giây để khớp animation loading
        group.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            group.leave()
        }
        
        // 4. Khi TẤT CẢ đã xong -> Chuyển màn hình
        group.notify(queue: .main) { [weak self] in
            // Ép thanh loading chạy nốt lên 100%
            self?.progressView.setProgress(1.0, animated: true)
            timer.invalidate()
            
            // Delay xíu cho người dùng thấy 100% rồi mới chuyển
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AppData.shared.hasDataLoaded = true
                self?.transitionToMainApp()
            }
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
        titleContainerView.addSubview(outlineLabel)
        titleContainerView.addSubview(foregroundLabel)
        
        progressContainerView.addSubview(progressView)
        
        [logoImageView, titleContainerView, subtitleLabel, loadingLabel, progressContainerView, disclaimerLabel].forEach {
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
            titleContainerView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 25),
            titleContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Ghim chặt lớp nền (viền trắng) vào giữa container
            outlineLabel.centerXAnchor.constraint(equalTo: titleContainerView.centerXAnchor),
            outlineLabel.centerYAnchor.constraint(equalTo: titleContainerView.centerYAnchor),
            // Cần thiết để container tự tính toán kích thước bao bọc label
            outlineLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            outlineLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            // Ghim chặt lớp trên (chữ xanh) trùng khít với lớp nền
            foregroundLabel.centerXAnchor.constraint(equalTo: outlineLabel.centerXAnchor),
            foregroundLabel.centerYAnchor.constraint(equalTo: outlineLabel.centerYAnchor),
            
            // 3. Subtitle: Dưới Title
            subtitleLabel.topAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 4. Disclaimer: Nằm sát đáy màn hình (cách bottom safe area)
            disclaimerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            disclaimerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 5. Progress Bar (Trên Disclaimer)
            progressContainerView.bottomAnchor.constraint(equalTo: disclaimerLabel.topAnchor, constant: -20),
            progressContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            progressContainerView.heightAnchor.constraint(equalToConstant: 24),
            
            // 6. Progress View (Ruột bên trong)
            progressView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: progressContainerView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
            
            // 7. Loading: Nằm trên Disclaimer
            loadingLabel.bottomAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: -10),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    //components
    private let progressContainerView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor.white
            v.layer.cornerRadius = 12
            
            // 1. Viền trắng dày bao quanh
            v.layer.borderWidth = 3
            v.layer.borderColor = UIColor.white.cgColor
            
            // 2. Đổ bóng khối cho cả thanh
            v.layer.shadowColor = UIColor.black.cgColor
            v.layer.shadowOffset = CGSize(width: 0, height: 4)
            v.layer.shadowOpacity = 0.3
            v.layer.shadowRadius = 0
            
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()
    
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
