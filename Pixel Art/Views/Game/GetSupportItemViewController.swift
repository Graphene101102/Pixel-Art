import UIKit

// Protocol để GameViewController xử lý sự kiện
protocol GetSupportItemDelegate: AnyObject {
    func didTapWatchVideoForSupport() // Xử lý khi bấm xem video nhận item
    func didTapCloseSupportPopup()    // Xử lý khi bấm đóng
}

class GetSupportItemViewController: UIViewController {
    
    weak var delegate: GetSupportItemDelegate?
    
    // MARK: - UI Elements
    
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return v
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        return v
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#007AFF")
        return btn
    }()
    
    private let itemImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = "Watch a short video to get\nmore item support"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    private let watchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor(hex: "#5856D6")
        btn.layer.cornerRadius = 25
        
        if let icon = UIImage(named: "clipIcon") {
            btn.setImage(icon, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "play.rectangle.fill"), for: .normal)
        }
        
        btn.setTitle(" Watch Now!", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        btn.tintColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        
        btn.layer.shadowColor = UIColor(hex: "#5856D6").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 6
        
        return btn
    }()
    
    // MARK: - Configuration
    // [LOGIC MỚI] Hàm cấu hình Icon dựa trên loại Item
    func configurePopup(for type: GameViewModel.ItemType) {
        // Cần đảm bảo View đã load để outlet không nil, hoặc set trong viewDidLoad thông qua biến
        if type == .magicWand {
            if let img = UIImage(named: "magicIcon") {
                itemImageView.image = img
            } else {
                itemImageView.image = UIImage(systemName: "wand.and.stars")
            }
        } else if type == .search {
            if let img = UIImage(named: "searchIcon") {
                itemImageView.image = img
            } else {
                itemImageView.image = UIImage(systemName: "magnifyingglass")
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        [closeButton, itemImageView, messageLabel, watchButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            itemImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            itemImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            itemImageView.widthAnchor.constraint(equalToConstant: 80),
            itemImageView.heightAnchor.constraint(equalToConstant: 80),
            
            messageLabel.topAnchor.constraint(equalTo: itemImageView.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            watchButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 25),
            watchButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            watchButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            watchButton.heightAnchor.constraint(equalToConstant: 50),
            watchButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
    }
    
    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapClose))
        dimView.addGestureRecognizer(tap)
        
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        watchButton.addTarget(self, action: #selector(didTapWatch), for: .touchUpInside)
        
        watchButton.addTarget(self, action: #selector(animateButtonDown), for: .touchDown)
        watchButton.addTarget(self, action: #selector(animateButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func didTapClose() {
        delegate?.didTapCloseSupportPopup()
        dismiss(animated: true)
    }
    
    @objc private func didTapWatch() {
        delegate?.didTapWatchVideoForSupport()
        dismiss(animated: true)
    }
    
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
