import UIKit

class CropViewController: UIViewController {
    
    // Closure trả kết quả về nơi gọi: (Ảnh đã crop, Tên, Danh mục)
    var onDidCrop: ((UIImage, String, String) -> Void)?
    
    private let originalImage: UIImage
    
    // --- UI Elements ---
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        return iv
    }()
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Đặt tên cho tác phẩm"
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 8
        tf.textAlignment = .center
        tf.returnKeyType = .done
        return tf
    }()
    
    private let bottomContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        return v
    }()
    
    // --- Init ---
    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // --- Lifecycle ---
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        imageView.image = originalImage
        nameTextField.delegate = self
    }
    
    private func setupUI() {
        // Navigation Bar
        title = "Tạo Pixel Art"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Hủy", style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(didTapDone))
        
        // Layout
        view.addSubview(imageView)
        view.addSubview(bottomContainer)
        bottomContainer.addSubview(nameTextField)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container dưới chứa input
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // TextField
            nameTextField.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            nameTextField.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Image View (Nằm giữa safe area và bottom container)
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor)
        ])
    }
    
    // --- Actions ---
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
    
    @objc private func didTapDone() {
        guard let finalImage = imageView.image else { return }
        
        // Lấy tên người dùng nhập, nếu không có thì đặt mặc định
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? nameTextField.text! : "My Art"
        let category = "My Imports"
        
        // Trả dữ liệu về
        onDidCrop?(finalImage, name, category)
        
        // Đóng màn hình
        dismiss(animated: true)
    }
}

extension CropViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
