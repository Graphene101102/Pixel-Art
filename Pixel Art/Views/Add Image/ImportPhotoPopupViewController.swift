import UIKit
import PhotosUI
import AVFoundation

// Protocol để bắn tín hiệu ra ngoài khi chọn ảnh xong
protocol ImportPhotoPopupDelegate: AnyObject {
    func didSelectImage(_ image: UIImage)
}

class ImportPhotoPopupViewController: UIViewController {
    
    weak var delegate: ImportPhotoPopupDelegate?
    
    // Nền mờ
    private let dimmedView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        v.alpha = 0
        return v
    }()
    
    // Container trắng bo góc
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        return v
    }()
    
    // Nút đóng (X)
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = .lightGray
        btn.backgroundColor = UIColor(white: 0.95, alpha: 1)
        btn.layer.cornerRadius = 15
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Import Your Photo"
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = UIColor(hex: "#3475CB")
        l.textAlignment = .center
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Create your own pixel art!\nChoose a photo from your camera or gallery to start coloring."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .gray
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    // Nút Camera
    private lazy var cameraButton: ImportOptionButton = {
        let btn = ImportOptionButton(iconName: "camera.fill", title: "Take a Photo", subtitle: "Use your camera", color: UIColor(hex: "#3475CB"))
        btn.addTarget(self, action: #selector(didTapCamera), for: .touchUpInside)
        return btn
    }()
    
    // Nút Gallery
    private lazy var galleryButton: ImportOptionButton = {
        let btn = ImportOptionButton(iconName: "photo.fill", title: "Pick from Gallery", subtitle: "From your device", color: UIColor(hex: "#3475CB"))
        btn.addTarget(self, action: #selector(didTapGallery), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3) { self.dimmedView.alpha = 0.5 }
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(cameraButton)
        containerView.addSubview(galleryButton)
        
        dimmedView.frame = view.bounds
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            cameraButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            cameraButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cameraButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cameraButton.heightAnchor.constraint(equalToConstant: 100),
            
            galleryButton.topAnchor.constraint(equalTo: cameraButton.bottomAnchor, constant: 15),
            galleryButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            galleryButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            galleryButton.heightAnchor.constraint(equalToConstant: 100),
            galleryButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30)
        ])
        
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    }
    
    @objc private func didTapClose() {
        UIView.animate(withDuration: 0.3, animations: {
            self.dimmedView.alpha = 0
            self.dismiss(animated: true)
        })
    }
    
    // MARK: - Xử lý Camera an toàn
    @objc private func didTapCamera() {
        // 1. Kiểm tra thiết bị có Camera không
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Lỗi", message: "Thiết bị này không có Camera hoặc đang chạy trên Simulator.")
            return
        }
        
        // 2. Kiểm tra quyền truy cập Camera
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
            openCamera() // Đã cấp quyền -> Mở luôn
        case .notDetermined:
            // Chưa hỏi bao giờ -> Hiện popup xin quyền
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async { self.openCamera() }
                }
            }
        case .denied, .restricted:
            // Đã từ chối -> Hướng dẫn vào cài đặt
            showSettingsAlert()
        @unknown default:
            break
        }
    }
    private func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false // Tắt edit mặc định để dùng CropView xịn của mình
        present(picker, animated: true)
    }
    
    private func showSettingsAlert() {
        let alert = UIAlertController(title: "Cần quyền Camera", message: "Vui lòng cấp quyền truy cập Camera trong Cài đặt để chụp ảnh.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cài đặt", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func didTapGallery() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - Delegates
extension ImportPhotoPopupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            dismiss(animated: true) { self.delegate?.didSelectImage(image) }
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first else { return }
        if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.dismiss(animated: true) {
                            self?.delegate?.didSelectImage(uiImage)
                        }
                    }
                }
            }
        }
    }
}

// Button Custom cho đẹp
class ImportOptionButton: UIButton {
    init(iconName: String, title: String, subtitle: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = UIColor(white: 0.95, alpha: 1).cgColor
        
        // Shadow nhẹ
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 18, weight: .bold)
        titleLbl.textColor = .black
        
        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 14)
        subLbl.textColor = .gray
        
        addSubview(iconView)
        addSubview(titleLbl)
        addSubview(subLbl)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        subLbl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLbl.topAnchor.constraint(equalTo: topAnchor, constant: 25),
            titleLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 15),
            
            subLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
            subLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 15)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
