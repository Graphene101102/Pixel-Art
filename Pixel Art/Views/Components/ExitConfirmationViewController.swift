import UIKit

// Protocol để báo ngược lại cho màn hình cha biết là người dùng ĐỒNG Ý thoát
protocol ExitConfirmationDelegate: AnyObject {
    func didConfirmExit()
}

class ExitConfirmationViewController: UIViewController {
    //MARK: - pillButton
    class PillGradientButton: UIButton {
        private let gradientLayer = CAGradientLayer()
        
        init(colors: [UIColor]) {
            super.init(frame: .zero)
            // Cấu hình Gradient từ trên xuống dưới
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // Trên
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)   // Dưới
            
            // Chèn lớp màu xuống dưới cùng
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // Cập nhật frame cho gradient
            gradientLayer.frame = bounds
            
            let radius = bounds.height / 2
            layer.cornerRadius = radius
            gradientLayer.cornerRadius = radius
        }
    }
    
    weak var delegate: ExitConfirmationDelegate?
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "exitPopup")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel1: UILabel = {
        let l = UILabel()
        l.text = "Exit drawing?"
        l.font = .systemFont(ofSize: 22, weight: .semibold) // Font đậm
        l.textColor = UIColor(hex: "#1C1C1E") // Màu đen xám
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    
    private let titleLabel2: UILabel = {
        let l = UILabel()
        l.text = "Your progress might be lost."
        l.font = .systemFont(ofSize: 20, weight: .thin) // Font đậm
        l.textColor = UIColor(hex: "#1C1C1E").withAlphaComponent(0.7)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    
    // Nút "No, Stay" (Màu xanh nhạt)
    private let stayButton: PillGradientButton = {
        let btn = PillGradientButton(colors: [
            UIColor(hex: "#27A7FF"),
            UIColor(hex: "#47B4FF"),
            UIColor(hex: "#039AFF")
        ])
        // 1. chữ
        btn.setTitle("No, Stay", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .heavy)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        // 2. Viền trắng dày
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        
        // 3. Shadow cho nút
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        
        return btn
    }()
    
    // Nút "Exit Drawing" (Màu tím/xanh đậm)
    private let exitButton: PillGradientButton = {
        let btn = PillGradientButton(colors: [
            UIColor(hex: "#5856D6"),
            UIColor(hex: "#5856D6"),
            UIColor(hex: "#5856D6")
        ])
        
        // 1. chữ
        btn.setTitle("Exit Drawing", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .heavy)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        // 2. Viền trắng dày
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        
        // 3. Shadow cho nút
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        
        return btn
    }()
    
    // MARK: - Init
    init() {
        super.init(nibName: nil, bundle: nil)
        // Cấu hình để hiện popup đè lên (trong suốt)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Nền đen mờ 40%
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel1)
        containerView.addSubview(titleLabel2)
        containerView.addSubview(stayButton)
        containerView.addSubview(exitButton)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel1.translatesAutoresizingMaskIntoConstraints = false
        titleLabel2.translatesAutoresizingMaskIntoConstraints = false
        stayButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container căn giữa màn hình
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel1.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            titleLabel2.topAnchor.constraint(equalTo: titleLabel1.bottomAnchor, constant: 10),
            titleLabel2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Stay Button
            stayButton.topAnchor.constraint(equalTo: titleLabel2.bottomAnchor, constant: 15),
            stayButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            stayButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            stayButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Exit Button
            exitButton.topAnchor.constraint(equalTo: stayButton.bottomAnchor, constant: 15),
            exitButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            exitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            exitButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Bottom của Container
            containerView.bottomAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 20)
        ])
        
        // Actions
        stayButton.addTarget(self, action: #selector(didTapStay), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(didTapExit), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func didTapStay() {
        // Chỉ cần tắt popup
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapExit() {
        // Tắt popup xong thì báo cho Delegate thực hiện lệnh thoát thật
        dismiss(animated: true) {
            self.delegate?.didConfirmExit()
        }
    }
}


