import UIKit

class StartViewController: UIViewController {

    // 1. UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "PIXEL ART"
        label.font = .systemFont(ofSize: 60, weight: .heavy)
        label.textColor = .black
        label.textAlignment = .center
        
        // Hiệu ứng bóng đổ cho chữ
        label.layer.shadowColor = UIColor.gray.cgColor
        label.layer.shadowOffset = CGSize(width: 2, height: 2)
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 2
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let coloringButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("TÔ MÀU", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 24)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 30
        // Shadow cho nút
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let libraryButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("THƯ VIỆN", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 24)
        btn.backgroundColor = .systemGreen // Màu khác để phân biệt
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 30
        
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // 2. Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // 3. Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(titleLabel)
        view.addSubview(coloringButton)
        view.addSubview(libraryButton)
        
        NSLayoutConstraint.activate([
            // Title nằm ở khoảng 1/4 màn hình từ trên xuống
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Nút Tô màu (Ở giữa màn hình)
            coloringButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coloringButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coloringButton.widthAnchor.constraint(equalToConstant: 250), // Nút lớn
            coloringButton.heightAnchor.constraint(equalToConstant: 70),
            
            // Nút Thư viện (Nằm dưới nút Tô màu)
            libraryButton.topAnchor.constraint(equalTo: coloringButton.bottomAnchor, constant: 30),
            libraryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            libraryButton.widthAnchor.constraint(equalTo: coloringButton.widthAnchor),
            libraryButton.heightAnchor.constraint(equalTo: coloringButton.heightAnchor)
        ])
    }
    
    private func setupActions() {
        coloringButton.addTarget(self, action: #selector(didTapColoring), for: .touchUpInside)
        libraryButton.addTarget(self, action: #selector(didTapLibrary), for: .touchUpInside)
    }
    
    // 4. Actions
    @objc private func didTapColoring() {
        let vc = FreeStyleViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapLibrary() {
        let vc = HomeViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
