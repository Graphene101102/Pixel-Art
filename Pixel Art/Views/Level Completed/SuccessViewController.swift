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
        l.textColor = UIColor(hex: "#82AAFF")
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
    
    private let imageContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        
        // Shadow (Đã chỉnh theo yêu cầu trước: lệch phải, lệch dưới)
        v.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        v.layer.shadowOpacity = 0.7
        v.layer.shadowOffset = CGSize(width: 8, height: 10)
        v.layer.shadowRadius = 15
        return v
    }()
    
    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
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
        // Shadow
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        return btn
    }()
    
    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(" SHARE", for: .normal)
        btn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor(hex: "#47B4FF")
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 16
        // Shadow
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
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(homeButton)
        view.addSubview(imageContainer)
        imageContainer.addSubview(artworkImageView)
        
        view.addSubview(timeStatView)
        view.addSubview(pixelStatView)
        view.addSubview(saveButton)
        view.addSubview(shareButton)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkImageView.translatesAutoresizingMaskIntoConstraints = false
        timeStatView.translatesAutoresizingMaskIntoConstraints = false
        pixelStatView.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Cấu hình padding
        let padding: CGFloat = 12
        let imageAspectRatio = finalImage.size.height / finalImage.size.width
        
        NSLayoutConstraint.activate([
            // --- HEADER ---
            homeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            homeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            homeButton.widthAnchor.constraint(equalToConstant: 44),
            homeButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // --- IMAGE CONTAINER ---
            imageContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            imageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Container bám sát ImageView + padding
            imageContainer.topAnchor.constraint(equalTo: artworkImageView.topAnchor, constant: -padding),
            imageContainer.bottomAnchor.constraint(equalTo: artworkImageView.bottomAnchor, constant: padding),
            imageContainer.leadingAnchor.constraint(equalTo: artworkImageView.leadingAnchor, constant: -padding),
            imageContainer.trailingAnchor.constraint(equalTo: artworkImageView.trailingAnchor, constant: padding),
            
            // Kích thước ImageView
            artworkImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            artworkImageView.heightAnchor.constraint(equalTo: artworkImageView.widthAnchor, multiplier: imageAspectRatio), 
            
            // --- STATS ROW ---
            // Neo TimeStat vào đáy của ImageContainer
            timeStatView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 30),
            timeStatView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            timeStatView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            timeStatView.heightAnchor.constraint(equalToConstant: 80),
            
            pixelStatView.topAnchor.constraint(equalTo: timeStatView.topAnchor),
            pixelStatView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            pixelStatView.widthAnchor.constraint(equalTo: timeStatView.widthAnchor),
            pixelStatView.heightAnchor.constraint(equalTo: timeStatView.heightAnchor),
            
            // --- BUTTONS ROW (ĐÃ SỬA) ---
            // Thay vì neo vào bottomAnchor của View, ta neo vào bottomAnchor của Stats View
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: timeStatView.bottomAnchor, constant: 30), // Cách Stat 20pt
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            saveButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            
            // Share Button
            shareButton.topAnchor.constraint(equalTo: saveButton.topAnchor), // Ngang hàng với Save
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            shareButton.widthAnchor.constraint(equalTo: saveButton.widthAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func createStatView(icon: String, title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.05
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        
        let iconImg = UIImageView(image: UIImage(systemName: icon))
        iconImg.tintColor = UIColor(hex: "#47B4FF")
        iconImg.contentMode = .scaleAspectFit
        
        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 12, weight: .bold)
        titleLbl.textColor = UIColor(hex: "#47B4FF")
        
        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .systemFont(ofSize: 20, weight: .bold)
        valueLbl.textColor = .black
        valueLbl.textAlignment = .center
        
        container.addSubview(iconImg)
        container.addSubview(titleLbl)
        container.addSubview(valueLbl)
        
        iconImg.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        valueLbl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImg.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            iconImg.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
            iconImg.widthAnchor.constraint(equalToConstant: 16),
            iconImg.heightAnchor.constraint(equalToConstant: 16),
            
            titleLbl.leadingAnchor.constraint(equalTo: iconImg.trailingAnchor, constant: 5),
            titleLbl.centerYAnchor.constraint(equalTo: iconImg.centerYAnchor),
            
            valueLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLbl.topAnchor.constraint(equalTo: iconImg.bottomAnchor, constant: 10)
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
        UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Lỗi lưu ảnh", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Artwork saved to your Photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc private func didTapShare() {
        let ac = UIActivityViewController(activityItems: [finalImage], applicationActivities: nil)
        present(ac, animated: true)
    }
}
