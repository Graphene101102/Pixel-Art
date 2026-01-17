import UIKit

class CropViewController: UIViewController, UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // --- Data ---
    private let originalImage: UIImage
    // Callback trả về: (Ảnh đã cắt, Tên level, Danh mục)
    var onDidCrop: ((UIImage, String, String) -> Void)?
    
    // Dữ liệu danh mục (Bỏ "Tất cả" vì khi tạo mới phải chọn 1 cái cụ thể)
    private let categories = ["Động vật", "Đồ ăn", "Phong cảnh", "Nhân vật", "Khác"]
    private var selectedCategory = "Khác"
    
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
    
    // UI chọn danh mục
    private let categoryTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Chọn danh mục"
        tf.borderStyle = .roundedRect
        tf.textAlignment = .center
        tf.text = "Khác" // Giá trị mặc định
        tf.tintColor = .clear // Ẩn con trỏ nhấp nháy
        return tf
    }()
    
    private let categoryPicker = UIPickerView()
    
    // Khung nhìn crop
    private let cropContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.yellow.cgColor
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
        
        // Cấu hình PickerView
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        // Gán picker làm bàn phím cho textfield
        categoryTextField.inputView = categoryPicker
        
        // Thêm toolbar có nút "Xong" cho Picker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([flexSpace, doneBtn], animated: true)
        categoryTextField.inputAccessoryView = toolbar
        nameTextField.inputAccessoryView = toolbar // Thêm nút xong cho cả ô nhập tên
        
        setupUI()
        setupImageInScrollView()
    }
    
    // --- Setup UI ---
    private func setupUI() {
        // Add Subviews
        view.addSubview(titleLabel)
        view.addSubview(nameTextField)
        view.addSubview(categoryTextField) // Thêm ô chọn danh mục
        view.addSubview(cropContainerView)
        cropContainerView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(hintLabel)
        view.addSubview(saveButton)
        
        // Disable AutoResizingMask
        [titleLabel, nameTextField, categoryTextField, cropContainerView, scrollView, imageView, hintLabel, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Layout Constraints
        let cropSize: CGFloat = 300
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Ô Nhập Tên
            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Ô Chọn Danh Mục (Nằm ngay dưới tên)
            categoryTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 12),
            categoryTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            categoryTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            categoryTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Khung Crop (Nằm dưới danh mục)
            cropContainerView.topAnchor.constraint(equalTo: categoryTextField.bottomAnchor, constant: 20),
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
    
    // --- Image Setup ---
    private func setupImageInScrollView() {
        scrollView.delegate = self
        imageView.image = originalImage
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: originalImage.size)
        scrollView.contentSize = originalImage.size
        
        let cropSize: CGFloat = 300
        let scaleWidth = cropSize / originalImage.size.width
        let scaleHeight = cropSize / originalImage.size.height
        let minScale = max(scaleWidth, scaleHeight)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = minScale
        
        centerImage()
    }
    
    private func centerImage() {
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
    
    // --- ScrollView Delegate ---
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
    
    // --- UIPickerView Delegate & DataSource ---
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory = categories[row]
        categoryTextField.text = selectedCategory
    }
    
    // --- Logic Save ---
    @objc private func didTapSave() {
        // Validate tên
        guard let name = nameTextField.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            shakeView(nameTextField)
            return
        }
        
        // Validate category (đề phòng rỗng)
        if categoryTextField.text?.isEmpty ?? true {
            shakeView(categoryTextField)
            return
        }
        
        if let croppedImage = cropImage() {
            // Gọi callback trả về HomeVC
            onDidCrop?(croppedImage, name, selectedCategory)
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func cropImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        let image = renderer.image { context in
            context.cgContext.translateBy(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y)
            scrollView.layer.render(in: context.cgContext)
        }
        return image
    }
    
    // Hiệu ứng rung lắc khi lỗi
    private func shakeView(_ viewToShake: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        viewToShake.layer.add(animation, forKey: "shake")
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
