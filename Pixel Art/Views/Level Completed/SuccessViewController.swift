import UIKit

class SuccessViewController: UIViewController {

    // Dữ liệu nhận vào
    private let finalImage: UIImage
    private let timeSpent: TimeInterval
    private let totalPixels: Int

    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Congratulations"
        l.font = .systemFont(ofSize: 18, weight: .regular)
        l.textColor = UIColor(hex: "#82AAFF").withAlphaComponent(0.8)
        l.textAlignment = .center
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Pixel Perfect!"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    private let homeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        btn.setImage(UIImage(named: "home"), for: .normal)
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor(hex: "#3475CB").cgColor
        btn.layer.cornerRadius = 16
        return btn
    }()
    
    // Container ảnh chính
    private let imageContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        
        // 1. Viền trắng dày 6pt
        v.layer.borderWidth = 6
        v.layer.borderColor = UIColor.white.cgColor
        
        // 2. [SỬA] Đổi màu bóng sang Xanh dương cho đẹp và đồng bộ
        v.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        v.layer.shadowOpacity = 0.4
        v.layer.shadowOffset = CGSize(width: 8, height: 12)
        v.layer.shadowRadius = 10
        
        v.clipsToBounds = false // Để hiện bóng
        return v
    }()
    
    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        return iv
    }()
    
    // Icon Cúp (Giữ nguyên)
    private let cupIconView: UIImageView = {
        let iv = UIImageView()
        if let img = UIImage(named: "cup") {
            iv.image = img
        } else {
            iv.image = UIImage(systemName: "trophy.circle.fill")
        }
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(hex: "#27A7FF")
        
        iv.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        iv.layer.shadowOpacity = 1
        iv.layer.shadowOffset = CGSize(width: 2, height: 4)
        iv.layer.shadowRadius = 4
        return iv
    }()
    
    private lazy var timeStatView = createStatView(icon: "clock.fill", title: "TIME", value: formatTime(timeSpent))
    private lazy var pixelStatView = createStatView(icon: "paintpalette.fill", title: "PIXELS", value: "\(totalPixels)")
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(" Save", for: .normal)
        btn.setImage(UIImage(named: "saveIcon"), for: .normal)
        btn.setTitleColor(UIColor(hex: "#47B4FF"), for: .normal)
        btn.tintColor = UIColor(hex: "#47B4FF")
        btn.backgroundColor = .white
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 16
        
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#CBE8F3").cgColor
        btn.layer.shadowColor = UIColor(hex: "#0D9BE2").withAlphaComponent(0.3).cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 4, height: 4)
        btn.layer.shadowRadius = 0
        return btn
    }()
    
    private let shareButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(" SHARE", for: .normal)
        btn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor(hex: "#27A7FF")
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .black)
        btn.layer.cornerRadius = 16
        
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        return btn
    }()

    // MARK: - Init
    init(image: UIImage, timeSpent: TimeInterval, totalPixels: Int) {
        self.finalImage = image
        self.timeSpent = timeSpent
        self.totalPixels = totalPixels
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#F0F8FF")
        setupUI()
        artworkImageView.image = finalImage
        
        homeButton.addTarget(self, action: #selector(didTapHome), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        
        let bgView = AppBackgroundView()
        view.addSubview(bgView)
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(bgView)
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(homeButton)
        
        view.addSubview(imageContainer)
        imageContainer.addSubview(artworkImageView)
        
        // Thêm Cúp nằm đè lên container (nhưng add vào view cha để dễ quản lý constraints lòi ra ngoài)
        view.addSubview(cupIconView)
        
        view.addSubview(timeStatView)
        view.addSubview(pixelStatView)
        view.addSubview(saveButton)
        view.addSubview(shareButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        cupIconView.translatesAutoresizingMaskIntoConstraints = false
        timeStatView.translatesAutoresizingMaskIntoConstraints = false
        pixelStatView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        let imageAspectRatio = finalImage.size.height / finalImage.size.width
        
        NSLayoutConstraint.activate([
            // HEADER
            homeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            homeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            homeButton.widthAnchor.constraint(equalToConstant: 44),
            homeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // [SỬA] Đẩy Title lên cao hơn (giảm constant từ 40 -> 20)
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // IMAGE CONTAINER
            // [SỬA] Giảm khoảng cách từ Subtitle xuống Container (30 -> 20)
            imageContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            imageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // [SỬA] Thu nhỏ preview (0.65 -> 0.55)
            imageContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: imageAspectRatio),
            
            artworkImageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            artworkImageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            artworkImageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            artworkImageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            
            // CUP ICON
            cupIconView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 20),
            cupIconView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 20),
            cupIconView.widthAnchor.constraint(equalToConstant: 60),
            cupIconView.heightAnchor.constraint(equalToConstant: 60),
            
            // STATS ROW
            // [SỬA] Giảm khoảng cách từ Container xuống Stats (40 -> 30)
            timeStatView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 30),
            timeStatView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            timeStatView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            timeStatView.heightAnchor.constraint(equalToConstant: 90),
            
            pixelStatView.topAnchor.constraint(equalTo: timeStatView.topAnchor),
            pixelStatView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            pixelStatView.widthAnchor.constraint(equalTo: timeStatView.widthAnchor),
            pixelStatView.heightAnchor.constraint(equalTo: timeStatView.heightAnchor),
            
            // BUTTONS ROW
            saveButton.topAnchor.constraint(equalTo: timeStatView.bottomAnchor, constant: 25),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            
            shareButton.topAnchor.constraint(equalTo: saveButton.topAnchor),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            shareButton.widthAnchor.constraint(equalTo: saveButton.widthAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func createStatView(icon: String, title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        
        container.layer.shadowColor = UIColor(hex: "#0C53CE").withAlphaComponent(0.25).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowOffset = CGSize(width: 4, height: 4)
        container.layer.shadowRadius = 4
        
        let iconImg = UIImageView(image: UIImage(systemName: icon))
        iconImg.tintColor = UIColor(hex: "#47B4FF")
        iconImg.contentMode = .scaleAspectFit
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 13, weight: .heavy)
        titleLbl.textColor = UIColor(hex: "#47B4FF")
        
        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .systemFont(ofSize: 22, weight: .bold)
        valueLbl.textColor = .black
        valueLbl.textAlignment = .center
        
        let headerStack = UIStackView(arrangedSubviews: [iconImg, titleLbl])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.distribution = .fill
        
        container.addSubview(headerStack)
        container.addSubview(valueLbl)
        
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        valueLbl.translatesAutoresizingMaskIntoConstraints = false
        iconImg.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImg.widthAnchor.constraint(equalToConstant: 18),
            iconImg.heightAnchor.constraint(equalToConstant: 18),
            
            headerStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
            
            valueLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLbl.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            valueLbl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -15)
        ])
        
        return container
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Actions
    @objc private func didTapHome() {
        view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapSave() {
        // Chỉ lưu Container (Tranh + Nền + Viền), KHÔNG LƯU CÚP (vì cúp nằm ngoài container)
        let renderer = UIGraphicsImageRenderer(bounds: imageContainer.bounds)
        let imageToSave = renderer.image { context in
            imageContainer.drawHierarchy(in: imageContainer.bounds, afterScreenUpdates: true)
        }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Artwork saved to your Photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc private func didTapShare() {
        let renderer = UIGraphicsImageRenderer(bounds: imageContainer.bounds)
        let imageToShare = renderer.image { context in
            imageContainer.drawHierarchy(in: imageContainer.bounds, afterScreenUpdates: true)
        }
        
        let ac = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
        present(ac, animated: true)
    }
}
