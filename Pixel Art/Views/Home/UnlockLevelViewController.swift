import UIKit

// Protocol để GameViewController xử lý sự kiện
protocol UnlockLevelDelegate: AnyObject {
    func didTapWatchVideo() // Xử lý khi bấm nút xem video
    func didTapCloseUnlockPopup() // Xử lý khi bấm nút đóng
}

class UnlockLevelViewController: UIViewController {
    
    weak var delegate: UnlockLevelDelegate?
    
    // MARK: - UI Elements
    
    // 1. Màn mờ phía sau
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return v
    }()
    
    // 2. Khung nội dung trắng
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        return v
    }()
    
    // 3. Nút đóng (X)
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        // Dùng SF Symbol cho nút đóng (giống ảnh là hình tròn xanh có dấu X trắng)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#007AFF") // Màu xanh dương giống ảnh
        return btn
    }()
    
    // 4. Ảnh Lock (Pixel Art)
    private let lockImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "lockIcon") // Asset: lockIcon
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // 5. Label nội dung
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = "Watch a short video to\nunlock this level?"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 0 // Cho phép xuống dòng
        return l
    }()
    
    // 6. Nút Watch Now
    private let watchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(hex: "#5856D6") // Màu tím giống ảnh
        btn.layer.cornerRadius = 25 // Bo tròn kiểu viên thuốc (Height 50 / 2)
        
        // Cấu hình Icon và Text
        if let icon = UIImage(named: "clipIcon") { // Asset: clipIcon
            btn.setImage(icon, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "play.rectangle.fill"), for: .normal)
        }
        
        btn.setTitle(" Watch Now!", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        btn.tintColor = .white
        
        // Padding để icon cách text ra một chút
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        
        // Shadow cho nút nổi bật
        btn.layer.shadowColor = UIColor(hex: "#5856D6").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Thêm các view
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        [closeButton, lockImageView, messageLabel, watchButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            // Dim View full màn hình
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Container ở giữa màn hình
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            // Chiều cao tự động dãn theo nội dung (nhờ constraints bottomAnchor bên dưới)
            
            // Nút đóng (Góc trên phải)
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Ảnh Lock
            lockImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            lockImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 80), // Kích thước icon lock
            lockImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Label thông báo
            messageLabel.topAnchor.constraint(equalTo: lockImageView.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Nút Watch Now
            watchButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 25),
            watchButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            watchButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            watchButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Neo đáy container (Quan trọng để container tự tính chiều cao)
            watchButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }
    
    // MARK: - Actions
    private func setupActions() {
        // Tap vào nền mờ để đóng (tùy chọn, nếu muốn bắt buộc xem thì bỏ dòng này)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapClose))
        dimView.addGestureRecognizer(tap)
        
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        watchButton.addTarget(self, action: #selector(didTapWatch), for: .touchUpInside)
        
        // Hiệu ứng nút bấm
        watchButton.addTarget(self, action: #selector(animateButtonDown), for: .touchDown)
        watchButton.addTarget(self, action: #selector(animateButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func didTapClose() {
        delegate?.didTapCloseUnlockPopup()
        dismiss(animated: true)
    }
    
    @objc private func didTapWatch() {
        // Gửi sự kiện cho Delegate xử lý (ví dụ: load quảng cáo)
        delegate?.didTapWatchVideo()
        dismiss(animated: true)
    }
    
    // Hiệu ứng nhún nút
    @objc private func animateButtonDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func animateButtonUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
}
