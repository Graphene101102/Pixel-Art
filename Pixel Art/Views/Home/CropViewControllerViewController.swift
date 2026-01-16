import UIKit

class CropViewController: UIViewController, UIScrollViewDelegate {
    
    // --- Data ---
    private let originalImage: UIImage
    // Callback trả về ảnh đã cắt và tên cho HomeVC xử lý
    var onDidCrop: ((UIImage, String) -> Void)?
    
    // --- UI Elements ---
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tạo màn chơi mới"
        lbl.font = .boldSystemFont(ofSize: 20)
        lbl.textAlignment = .center
        return lbl
    }()
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nhập tên tác phẩm (VD: Mario)"
        tf.borderStyle = .roundedRect
        tf.textAlignment = .center
        return tf
    }()
    
    // Khung nhìn crop (Hình vuông)
    private let cropContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.yellow.cgColor // Viền vàng để dễ căn
        v.clipsToBounds = true
        return v
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bouncesZoom = true
        return sv
    }()
    
    private let imageView = UIImageView()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Tạo Pixel Art", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 10
        return btn
    }()
    
    private let hintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Di chuyển và thu phóng ảnh vào khung vuông"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .gray
        lbl.textAlignment = .center
        return lbl
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
        view.backgroundColor = .systemBackground
        setupUI()
        setupImageInScrollView()
    }
    
    // --- Setup UI ---
    private func setupUI() {
        // Add Subviews
        view.addSubview(titleLabel)
        view.addSubview(nameTextField)
        view.addSubview(cropContainerView)
        cropContainerView.addSubview(scrollView) // ScrollView nằm trong Container
        scrollView.addSubview(imageView)
        view.addSubview(hintLabel)
        view.addSubview(saveButton)
        
        // Disable AutoResizingMask
        [titleLabel, nameTextField, cropContainerView, scrollView, imageView, hintLabel, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Layout
        let cropSize: CGFloat = 300 // Kích thước khung vuông crop
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Container hình vuông ở giữa
            cropContainerView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            cropContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cropContainerView.widthAnchor.constraint(equalToConstant: cropSize),
            cropContainerView.heightAnchor.constraint(equalToConstant: cropSize),
            
            // ScrollView full container
            scrollView.topAnchor.constraint(equalTo: cropContainerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cropContainerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cropContainerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cropContainerView.trailingAnchor),
            
            hintLabel.topAnchor.constraint(equalTo: cropContainerView.bottomAnchor, constant: 10),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Actions
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        
        // Dismiss keyboard khi tap ra ngoài
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func setupImageInScrollView() {
        scrollView.delegate = self
        imageView.image = originalImage
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: originalImage.size)
        scrollView.contentSize = originalImage.size
        
        // Tính toán scale ban đầu để ảnh vừa khít hoặc bao phủ khung
        let cropSize: CGFloat = 300
        let scaleWidth = cropSize / originalImage.size.width
        let scaleHeight = cropSize / originalImage.size.height
        let minScale = max(scaleWidth, scaleHeight) // Dùng max để ảnh luôn lấp đầy (Aspect Fill)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = minScale
        
        // Căn giữa ảnh ban đầu
        centerImage()
    }
    
    private func centerImage() {
        // Căn giữa scrollview
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
    
    // UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    // MARK: - Logic Cắt ảnh
    @objc private func didTapSave() {
        guard let name = nameTextField.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            // Rung báo lỗi nếu chưa nhập tên
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.duration = 0.6
            animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
            nameTextField.layer.add(animation, forKey: "shake")
            return
        }
        
        // Thực hiện CROP
        if let croppedImage = cropImage() {
            // Trả về HomeVC
            onDidCrop?(croppedImage, name)
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func cropImage() -> UIImage? {
        // Lấy đúng những gì đang hiển thị trong ScrollView:
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        let image = renderer.image { context in
            // Dịch chuyển context ngược lại với offset của scrollview để chụp đúng vùng
            context.cgContext.translateBy(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y)
            scrollView.layer.render(in: context.cgContext)
        }
        return image
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
