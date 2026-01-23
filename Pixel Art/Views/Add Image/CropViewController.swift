import UIKit

class CropViewController: UIViewController {
    
    // Callback trả về: Ảnh đã crop, Danh mục
    var onDidCrop: ((UIImage, String) -> Void)?
    
    private let originalImage: UIImage
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.alwaysBounceHorizontal = true
        sv.backgroundColor = .black
        // [QUAN TRỌNG] Tắt tự động tính inset để tự kiểm soát giới hạn kéo
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        // Quan trọng: Cần enable user interaction cho view được zoom
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    // Lớp phủ mờ xung quanh
    private let overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.isUserInteractionEnabled = false
        return v
    }()
    
    // Khung viền trắng (Crop Box)
    private let cropBoxView: UIView = {
        let v = UIView()
        v.layer.borderColor = UIColor.white.cgColor
        v.layer.borderWidth = 1
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private let guideLabel: UILabel = {
        let l = UILabel()
        l.text = "Di chuyển và Phóng to"
        l.textColor = .white
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        return l
    }()
    
    // MARK: - Init
    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupNavBar()
        setupLayout()
        setupScrollView()
    }
    
    // Đợi layout xong mới tính toán khung crop để chính xác kích thước màn hình
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Chỉ cấu hình 1 lần đầu tiên khi chưa zoom
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            configureCropRegion()
        }
    }
    
    // MARK: - Setup UI
    private func setupNavBar() {
        title = "Cắt Ảnh"
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Hủy", style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(didTapDone))
        navigationItem.rightBarButtonItem?.tintColor = UIColor(hex: "#3475CB")
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(overlayView)
        view.addSubview(cropBoxView)
        view.addSubview(guideLabel)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        cropBoxView.translatesAutoresizingMaskIntoConstraints = false
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ScrollView full màn hình
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Overlay full màn hình
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // CropBox: Hình vuông, nằm giữa, rộng bằng chiều ngang màn hình
            cropBoxView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cropBoxView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropBoxView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropBoxView.heightAnchor.constraint(equalTo: cropBoxView.widthAnchor), // Tỉ lệ 1:1
            
            // Label
            guideLabel.topAnchor.constraint(equalTo: cropBoxView.bottomAnchor, constant: 20),
            guideLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        imageView.image = originalImage
        // Đặt frame ban đầu cho imageView bằng kích thước ảnh gốc
        imageView.frame = CGRect(origin: .zero, size: originalImage.size)
        scrollView.contentSize = originalImage.size
    }
    
    // MARK: - Logic Cấu hình Crop (Căn giữa và Zoom Aspect Fill)
    private func configureCropRegion() {
        // 1. Tạo Mask lỗ hổng hình vuông
        let path = UIBezierPath(rect: overlayView.bounds)
        let cropPath = UIBezierPath(rect: cropBoxView.frame)
        path.append(cropPath)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = UIColor.black.cgColor
        overlayView.layer.mask = maskLayer
        
        // 2. Tính toán Inset (Khoảng cách từ cạnh màn hình vào khung crop)
        let cropRect = cropBoxView.frame
        let topInset = cropRect.minY
        let bottomInset = view.frame.height - cropRect.maxY
        // Vì cropBox full width nên left/right inset = 0
        let sideInset: CGFloat = 0
        
        scrollView.contentInset = UIEdgeInsets(top: topInset, left: sideInset, bottom: bottomInset, right: sideInset)
        
        // 3. Tính toán Zoom Scale (Aspect Fill)
        // Mục tiêu: Cạnh ngắn nhất của ảnh phải lấp đầy khung crop
        let scaleWidth = cropRect.width / originalImage.size.width
        let scaleHeight = cropRect.height / originalImage.size.height
        
        // Lấy max để đảm bảo Aspect Fill
        let minScale = max(scaleWidth, scaleHeight)
        
        // Quan trọng: Đặt minimumZoomScale để không cho zoom nhỏ hơn khung
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = minScale * 5.0
        
        // Set zoom hiện tại
        scrollView.zoomScale = minScale
        
        // 4. Căn giữa ảnh ban đầu
        // Tính kích thước nội dung sau khi zoom
        let contentWidth = originalImage.size.width * minScale
        let contentHeight = originalImage.size.height * minScale
        
        // Tính toán offset để đưa phần thừa ra giữa
        // (Content Size - Crop Size) / 2
        let offsetX = (contentWidth - cropRect.width) / 2
        let offsetY = (contentHeight - cropRect.height) / 2
        
        // Đặt contentOffset (cần trừ đi inset vì điểm bắt đầu là âm inset)
        scrollView.contentOffset = CGPoint(x: offsetX - sideInset, y: offsetY - topInset)
    }
    
    // MARK: - Actions
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
    
    @objc private func didTapDone() {
        if let cropped = cropImage() {
            onDidCrop?(cropped, "My Imports")
            dismiss(animated: true)
        }
    }
    
    // MARK: - Logic Cắt Ảnh (ĐÃ SỬA)
    private func cropImage() -> UIImage? {
        // 1. Chuẩn hoá hướng ảnh về .up để toạ độ không bị đảo lộn
        // Bước này cực kỳ quan trọng với ảnh chụp từ Camera
        guard let fixedImage = originalImage.normalizedImage(),
              let cgImage = fixedImage.cgImage else {
            return nil
        }
        
        // 2. Chuyển đổi toạ độ khung Crop (màn hình) sang toạ độ trên ImageView
        let cropRectInView = view.convert(cropBoxView.frame, to: imageView)
        
        // 3. Tính tỷ lệ scale giữa ảnh thực tế (Pixel) và ảnh hiển thị (Point)
        // Vì ảnh đã normalized nên dùng chiều rộng nào làm chuẩn cũng được
        let scale = CGFloat(cgImage.width) / imageView.bounds.width
        
        // 4. Tính khung cắt thực tế (Pixel)
        var cropRectInImage = CGRect(
            x: cropRectInView.origin.x * scale,
            y: cropRectInView.origin.y * scale,
            width: cropRectInView.size.width * scale,
            height: cropRectInView.size.height * scale
        )
        
        // 5. [QUAN TRỌNG] Ép buộc về hình vuông tuyệt đối
        // Lấy cạnh nhỏ nhất làm chuẩn để đảm bảo không bị cắt lẹm ra ngoài
        let sideLength = min(cropRectInImage.width, cropRectInImage.height)
        cropRectInImage.size = CGSize(width: sideLength, height: sideLength)
        
        // 6. Cắt ảnh
        guard let croppedCgImage = cgImage.cropping(to: cropRectInImage) else {
            return nil
        }
        
        // Trả về ảnh mới (scale 1.0 vì đã cắt trên pixel thật)
        return UIImage(cgImage: croppedCgImage)
    }
}

// MARK: - Delegate
extension CropViewController: UIScrollViewDelegate {
    // Cho biết view nào sẽ được zoom trong scrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension UIImage {
    func normalizedImage() -> UIImage? {
        if self.imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
