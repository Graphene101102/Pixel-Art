import UIKit

protocol DifficultySelectionDelegate: AnyObject {
    func didSelectLevelToPlay(_ level: LevelData)
}

class DifficultySelectionViewController: UIViewController {
    
    weak var delegate: DifficultySelectionDelegate?
    private let levelVariants: [LevelData]
    private var selectedLevel: LevelData?
    
    // MARK: - UI Elements
    
    // [ĐÃ SỬA] Nút Back (Style giống Game/LevelCompleted)
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        
        // Ưu tiên dùng icon trong Assets, nếu không có thì dùng system icon
        if let img = UIImage(named: "backIcon") {
            btn.setImage(img, for: .normal)
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            btn.setImage(UIImage(systemName: "arrow.backward", withConfiguration: config), for: .normal)
        }
        
        // Styling chuẩn
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        
        // Shadow
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose Level"
        l.font = .systemFont(ofSize: 24, weight: .black) // Đậm hơn chút cho đẹp
        l.textColor = UIColor(hex: "#3475CB")
        return l
    }()
    
    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.layer.borderWidth = 4
        iv.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        return iv
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 15
        s.distribution = .fillEqually
        return s
    }()
    
    private let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("START COLORING", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = UIColor(hex: "#3475CB")
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        
        // Shadow cho nút Start
        btn.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 5
        return btn
    }()
    
    private var optionButtons: [UIButton] = []
    
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
        view.backgroundColor = .white
        setupUI()
        updatePreview()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(previewImageView)
        view.addSubview(stackView)
        view.addSubview(startButton)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Action Back
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        // Tạo 3 nút chọn
        let easyBtn = createOptionButton(title: "Easy", sub: "10 colors", stars: 1, tag: 0)
        let mediumBtn = createOptionButton(title: "Medium", sub: "20 colors", stars: 2, tag: 1)
        let hardBtn = createOptionButton(title: "Hard", sub: "30 colors", stars: 3, tag: 2)
        
        optionButtons = [easyBtn, mediumBtn, hardBtn]
        optionButtons.forEach { stackView.addArrangedSubview($0) }
        
        if let first = optionButtons.first { didTapOption(first) }
        
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Back Button (Top Left)
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44), // Kích thước chuẩn nút vuông
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Title (Center Y with Back Button)
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Preview Image
            previewImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            previewImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65), // To hơn xíu
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor),
            
            // Options Stack
            stackView.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            stackView.heightAnchor.constraint(equalToConstant: 210), // Tăng chiều cao để nút thoáng hơn
            
            // Start Button
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            startButton.heightAnchor.constraint(equalToConstant: 54)
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
    
    private func createOptionButton(title: String, sub: String, stars: Int, tag: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = tag
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.systemGray5.cgColor
        
        let label = UILabel()
        label.text = "\(title)\n\(sub)"
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        
        let starLabel = UILabel()
        starLabel.text = String(repeating: "★", count: stars)
        starLabel.textColor = .systemYellow
        starLabel.font = .systemFont(ofSize: 18)
        
        let hStack = UIStackView(arrangedSubviews: [starLabel, label])
        hStack.axis = .horizontal
        hStack.spacing = 15
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false
        
        btn.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 20),
            hStack.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
        ])
        
        btn.addTarget(self, action: #selector(didTapOption(_:)), for: .touchUpInside)
        return btn
    }
    
    @objc private func didTapOption(_ sender: UIButton) {
        let index = sender.tag
        if index < levelVariants.count {
            self.selectedLevel = levelVariants[index]
            updatePreview()
        }
        optionButtons.forEach {
            $0.layer.borderColor = UIColor.systemGray5.cgColor
            $0.backgroundColor = .white
        }
        sender.layer.borderColor = UIColor(hex: "#3475CB").cgColor
        sender.backgroundColor = UIColor(hex: "#3475CB").withAlphaComponent(0.1)
    }
    
    // Action khi bấm Start
    @objc private func didTapStart() {
        guard let lvl = selectedLevel else { return }
        // Dismiss màn hình chọn này trước khi mở Game
        dismiss(animated: true) {
            self.delegate?.didSelectLevelToPlay(lvl)
        }
    }
    
    // [ACTION] Nút Back -> Quay lại Home
    @objc private func didTapBack() {
        // Hiệu ứng nút nhún nhẹ
        UIView.animate(withDuration: 0.1, animations: {
            self.backButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.backButton.transform = .identity
            } completion: { _ in
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
