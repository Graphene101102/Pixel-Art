import UIKit

// Protocol Delegate
protocol DifficultySelectionDelegate: AnyObject {
    func didSelectLevelToPlay(_ level: LevelData)
}

class DifficultySelectionViewController: UIViewController {
    
    weak var delegate: DifficultySelectionDelegate?
    private let levelVariants: [LevelData]
    private var selectedLevel: LevelData?
    private var optionButtons: [OptionButton] = []
    
    // MARK: - UI Elements
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        btn.setImage(UIImage(systemName: "arrow.backward", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#0097FF")
        
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor(hex: "#172554").cgColor
        
        btn.layer.shadowColor =  UIColor(hex: "#0097FF").withAlphaComponent(0.3).cgColor
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose Level"
        l.font = .systemFont(ofSize: 26, weight: .heavy)
        l.textColor = UIColor(hex: "#0097FF")
        return l
    }()
    
    private let previewContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 28
        
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor(hex: "#338CFF").cgColor
        
        v.layer.shadowColor = UIColor(hex: "#172554").cgColor
        v.layer.shadowOpacity = 1.0
        v.layer.shadowOffset = CGSize(width: 8, height: 8)
        v.layer.shadowRadius = 0
        
        return v
    }()
    
    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        return iv
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.distribution = .fillEqually
        return s
    }()
    
    // Start Button
    private let startButton: GradientButton = {
        let btn = GradientButton(colors: [
            UIColor(hex: "#27A7FF"),
            UIColor(hex: "#47B4FF"),
            UIColor(hex: "#039AFF")
        ])
        btn.setTitle("START COLORING", for: .normal)
        // 1. Font chữ đậm, to, có shadow cho chữ (như ảnh)
        btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .heavy)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        btn.titleLabel?.shadowOffset = CGSize(width: 1, height: 1)
        
        // 2. Màu nền :
        btn.backgroundColor = UIColor(hex: "#4A90E2")
        
        // 3. Bo góc tròn
        btn.layer.cornerRadius = 16
        
        // 4. Viền trắng dày
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor.white.cgColor
        
        // 5. Shadow cho nút
        btn.layer.shadowColor = UIColor.gray.cgColor
        btn.layer.shadowOpacity = 1.0
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 0
        
        return btn
    }()
    
    // MARK: - Init
    init(levels: [LevelData]) {
        self.levelVariants = levels.sorted { $0.difficulty < $1.difficulty }
        self.selectedLevel = self.levelVariants.first
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updatePreview()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        let bgView = AppBackgroundView()
        view.addSubview(bgView)
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(bgView)
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(previewContainer)
        previewContainer.addSubview(previewImageView)
        view.addSubview(stackView)
        view.addSubview(startButton)
        
        // Bật AutoLayout cho tất cả
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Actions
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
        
        // Create Options
        let easyBtn = OptionButton(title: "Easy", sub: "10 colors", stars: 1, tag: 0)
        let mediumBtn = OptionButton(title: "Medium", sub: "20 colors", stars: 2, tag: 1)
        let hardBtn = OptionButton(title: "Hard", sub: "30 colors", stars: 3, tag: 2)
        
        optionButtons = [easyBtn, mediumBtn, hardBtn]
        optionButtons.forEach {
            $0.addTarget(self, action: #selector(didTapOption(_:)), for: .touchUpInside)
            stackView.addArrangedSubview($0)
        }
        
        if let first = optionButtons.first { didTapOption(first) }
        
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Title
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Preview Container
            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            previewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            previewContainer.heightAnchor.constraint(equalTo: previewContainer.widthAnchor),
            
            // Image View
            previewImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 6),
            previewImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 6),
            previewImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -6),
            previewImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -6),
            
            // Options Stack
            stackView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.heightAnchor.constraint(equalToConstant: 250),
            
            // Start Button
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Logic
    private func updatePreview() {
        guard let level = selectedLevel else { return }
        let size = CGSize(width: level.gridWidth, height: level.gridHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            for pixel in level.pixels {
                if pixel.number > 0 {
                    pixel.rawColor.toUIColor.setFill()
                    ctx.fill(CGRect(x: pixel.x, y: pixel.y, width: 1, height: 1))
                }
            }
        }
        previewImageView.image = img
        previewImageView.layer.magnificationFilter = .nearest
    }
    
    @objc private func didTapOption(_ sender: OptionButton) {
        let index = sender.tag
        if index < levelVariants.count {
            self.selectedLevel = levelVariants[index]
            updatePreview()
        }
        optionButtons.forEach { $0.setSelected(false) }
        sender.setSelected(true)
    }
    
    @objc private func didTapStart() {
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            } completion: { _ in
                guard let lvl = self.selectedLevel else { return }
                
                self.delegate?.didSelectLevelToPlay(lvl)
            }
        }
    }
    
    @objc private func didTapBack() {
        // 1. Tạo animation trượt từ Trái sang Phải
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        transition.subtype = .fromLeft
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.window?.layer.add(transition, forKey: kCATransition)
        
        dismiss(animated: false, completion: nil)
    }
}

// MARK: - Helper Class: Gradient Button
class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    
    init(colors: [UIColor]) {
        super.init(frame: .zero)
        // Cấu hình Gradient
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }
}

// MARK: - Custom Option Button Class
class OptionButton: UIControl {
    
    private let starContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#0097FF").withAlphaComponent(0.2)
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor(hex: "#0097FF").withAlphaComponent(0.7).cgColor
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(hex: "#172554")
        return l
    }()
    
    private let subLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .gray
        return l
    }()
    
    // Container khoá level
    private let videoIconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.isHidden = true
        // Shadow nhẹ cho icon nổi bật
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 2
        return v
    }()
    
    private let videoIconImage: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "clipIcon")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()
    
    private var starCount: Int = 0
    
    init(title: String, sub: String, stars: Int, tag: Int) {
        super.init(frame: .zero)
        self.tag = tag
        self.starCount = stars
        setup(title: title, sub: sub)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(title: String, sub: String) {
        backgroundColor = .white
        layer.cornerRadius = 18
        layer.borderWidth = 2.5
        layer.borderColor = UIColor(hex: "#0097FF").withAlphaComponent(0.5).cgColor
        
        titleLabel.text = title
        subLabel.text = sub
        
        if starCount == 3 {
            videoIconContainer.isHidden = false
            addSubview(videoIconContainer)
            videoIconContainer.addSubview(videoIconImage)
            
            videoIconContainer.translatesAutoresizingMaskIntoConstraints = false
            videoIconImage.translatesAutoresizingMaskIntoConstraints = false
            
            //kích thước cho icon
            let iconSize: CGFloat = 28
            videoIconContainer.layer.cornerRadius = iconSize / 2
            
            NSLayoutConstraint.activate([
                videoIconContainer.centerYAnchor.constraint(equalTo: topAnchor),
                // CenterX trùng với Trailing của button
                videoIconContainer.centerXAnchor.constraint(equalTo: trailingAnchor),
                
                videoIconContainer.widthAnchor.constraint(equalToConstant: iconSize),
                videoIconContainer.heightAnchor.constraint(equalToConstant: iconSize),
                
                // Icon ảnh bên trong container
                videoIconImage.centerXAnchor.constraint(equalTo: videoIconContainer.centerXAnchor),
                videoIconImage.centerYAnchor.constraint(equalTo: videoIconContainer.centerYAnchor),
                videoIconImage.widthAnchor.constraint(equalToConstant: 16),
                videoIconImage.heightAnchor.constraint(equalToConstant: 16)
            ])
        }
        
        addSubview(starContainer)
        addSubview(titleLabel)
        addSubview(subLabel)
        
        starContainer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            starContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            starContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            starContainer.widthAnchor.constraint(equalToConstant: 48),
            starContainer.heightAnchor.constraint(equalToConstant: 48),
            
            titleLabel.topAnchor.constraint(equalTo: starContainer.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: starContainer.trailingAnchor, constant: 16),
            
            subLabel.bottomAnchor.constraint(equalTo: starContainer.bottomAnchor, constant: -2),
            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        ])
        
        setupStars()
    }
    
    private func setupStars() {
        let createStar = { () -> UILabel in
            let l = UILabel()
            l.text = "★"
            l.font = .systemFont(ofSize: 18, weight: .bold)
            l.textColor = UIColor(hex: "#FFBF00")
            l.sizeToFit()
            l.translatesAutoresizingMaskIntoConstraints = false
            return l
        }
        
        if starCount == 1 {
            let s1 = createStar()
            starContainer.addSubview(s1)
            NSLayoutConstraint.activate([
                s1.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor),
                s1.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor)
            ])
        } else if starCount == 2 {
            let s1 = createStar()
            let s2 = createStar()
            starContainer.addSubview(s1); starContainer.addSubview(s2)
            NSLayoutConstraint.activate([
                s1.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor),
                s1.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor, constant: -8),
                s2.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor),
                s2.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor, constant: 8)
            ])
        } else if starCount == 3 {
            let s1 = createStar(); let s2 = createStar(); let s3 = createStar()
            starContainer.addSubview(s1); starContainer.addSubview(s2); starContainer.addSubview(s3)
            NSLayoutConstraint.activate([
                s1.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor),
                s1.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor, constant: -8),
                s2.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor, constant: -8),
                s2.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor, constant: 8),
                s3.centerXAnchor.constraint(equalTo: starContainer.centerXAnchor, constant: 8),
                s3.centerYAnchor.constraint(equalTo: starContainer.centerYAnchor, constant: 8)
            ])
        }
    }
    
    func setSelected(_ selected: Bool) {
        if selected {
            layer.borderColor = UIColor(hex: "#0052B4").withAlphaComponent(0.5).cgColor
            backgroundColor = UIColor(hex: "#F4FAFF").withAlphaComponent(0.05)
        } else {
            layer.borderColor = UIColor(hex: "#AFD7FF").withAlphaComponent(0.5).cgColor
            backgroundColor = .white
        }
    }
}
