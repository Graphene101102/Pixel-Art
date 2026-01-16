import UIKit

class LevelCompletedViewController: UIViewController {

    private let level: LevelData
    
    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let previewCanvas = CanvasView()
    private let closeButton = UIButton(type: .system)
    
    init(level: LevelData) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6) // Nền tối mờ
        setupUI()
        setupConfetti()
    }
    
    private func setupUI() {
        // Container trắng ở giữa
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Label Chúc mừng
        titleLabel.text = "Tuyệt vời!"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .systemOrange
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Canvas xem lại tác phẩm
        previewCanvas.backgroundColor = .clear
        previewCanvas.layer.cornerRadius = 10
        previewCanvas.clipsToBounds = true
        previewCanvas.translatesAutoresizingMaskIntoConstraints = false
        previewCanvas.isUserInteractionEnabled = false
        containerView.addSubview(previewCanvas)
        
        // Nút Đóng
        closeButton.setTitle("Tiếp tục", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        closeButton.backgroundColor = .systemBlue
        closeButton.tintColor = .white
        closeButton.layer.cornerRadius = 25
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(closeButton)
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 400),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            previewCanvas.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            previewCanvas.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            previewCanvas.widthAnchor.constraint(equalToConstant: 200),
            previewCanvas.heightAnchor.constraint(equalToConstant: 200),
            
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 200),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        previewCanvas.render(level: level, currentNumber: -1)
    }
    
    private func setupConfetti() {
        containerView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            self.containerView.transform = .identity
        }, completion: nil)
    }
    
    @objc private func didTapClose() {
        // Thoát màn hình popup và quay về Home
        self.dismiss(animated: true) {
            // Tìm GameViewController bên dưới và thoát nó luôn để về Home
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootNav = windowScene.windows.first?.rootViewController as? UINavigationController {
                rootNav.popToRootViewController(animated: true)
            }
        }
    }
}
