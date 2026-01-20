import UIKit

// Protocol để báo ngược lại cho màn hình cha biết là người dùng ĐỒNG Ý thoát
protocol ExitConfirmationDelegate: AnyObject {
    func didConfirmExit()
}

class ExitConfirmationViewController: UIViewController {
    
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
        iv.image = UIImage(named: "exit") // Icon trong Assets
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Are you sure you\nwant to exit?"
        l.font = .systemFont(ofSize: 22, weight: .black) // Font đậm
        l.textColor = UIColor(hex: "#1C1C1E") // Màu đen xám
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    
    // Nút "No, Stay" (Màu xanh nhạt)
    private let stayButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("No, Stay", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = UIColor(hex: "#5AC8FA") // Màu xanh trời nhạt
        btn.tintColor = .white
        btn.layer.cornerRadius = 25 // Bo tròn nhiều
        
        // Shadow
        btn.layer.shadowColor = UIColor(hex: "#5AC8FA").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
        return btn
    }()
    
    // Nút "Exit Drawing" (Màu tím/xanh đậm)
    private let exitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Exit Drawing", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = UIColor(hex: "#5856D6") // Màu tím xanh
        btn.tintColor = .white
        btn.layer.cornerRadius = 25
        
        // Shadow
        btn.layer.shadowColor = UIColor(hex: "#5856D6").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
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
        containerView.addSubview(titleLabel)
        containerView.addSubview(stayButton)
        containerView.addSubview(exitButton)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stayButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container căn giữa màn hình
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Stay Button
            stayButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            stayButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            stayButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            stayButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Exit Button
            exitButton.topAnchor.constraint(equalTo: stayButton.bottomAnchor, constant: 15),
            exitButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            exitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            exitButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Bottom của Container
            containerView.bottomAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 30)
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
