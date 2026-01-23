import UIKit

protocol BackgroundSelectionDelegate: AnyObject {
    func didSelectBackgroundColor(_ color: UIColor)
}

class BackgroundSelectionViewController: UIViewController {
    
    // MARK: - Pixel Color Button (Chuẩn logic: Border nằm trên Cell)
    class PixelColorButton: UIButton {
        
        // LAYER 1: Lõi màu (Nằm dưới cùng)
        private let cellImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.backgroundColor = .clear
            iv.isUserInteractionEnabled = false
            if let img = UIImage(named: "cell") {
                iv.image = img.withRenderingMode(.alwaysTemplate)
            }
            return iv
        }()
        
        // LAYER 2: Viền Asset (Nằm đè lên trên)
        private let borderImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.backgroundColor = .clear
            iv.isUserInteractionEnabled = false
            if let img = UIImage(named: "border") {
                iv.image = img.withRenderingMode(.alwaysTemplate)
            }
            return iv
        }()
        
        // Constraints
        private var topConstraint: NSLayoutConstraint!
        private var bottomConstraint: NSLayoutConstraint!
        private var leadingConstraint: NSLayoutConstraint!
        private var trailingConstraint: NSLayoutConstraint!
        
        private var mainColor: UIColor
        
        override var isSelected: Bool {
            didSet {
                updateAppearance()
            }
        }
        
        init(color: UIColor) {
            self.mainColor = color
            super.init(frame: .zero)
            self.backgroundColor = .clear
            
            // 1. Add Cell trước (Layer dưới)
            addSubview(cellImageView)
            cellImageView.translatesAutoresizingMaskIntoConstraints = false
            cellImageView.tintColor = mainColor
            
            // 2. Add Border sau (Layer trên) -> Để viền đè lên cell
            addSubview(borderImageView)
            borderImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Setup Constraints cho Border (Luôn full nút)
            NSLayoutConstraint.activate([
                borderImageView.topAnchor.constraint(equalTo: self.topAnchor),
                borderImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                borderImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                borderImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
            
            // Setup Constraints cho Cell (Co giãn)
            topConstraint = cellImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0)
            bottomConstraint = cellImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
            leadingConstraint = cellImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0)
            trailingConstraint = cellImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0)
            
            NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
            
            updateAppearance()
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        private func updateAppearance() {
            UIView.animate(withDuration: 0.2) {
                if self.isSelected {
                    // === ĐANG CHỌN ===
                    
                    // 1. Viền đậm rõ (tối hơn 50%)
                    self.borderImageView.tintColor = self.mainColor.darker(by: 50) ?? .black
                    
                    // 2. Cell co vào (Zoom in)
                    let padding: CGFloat = 6
                    self.topConstraint.constant = padding
                    self.bottomConstraint.constant = -padding
                    self.leadingConstraint.constant = padding
                    self.trailingConstraint.constant = -padding
                    
                } else {
                    // === KHÔNG CHỌN ===
                    
                    // 1. Viền vẫn hiện, nhưng chỉ tối hơn một chút (20%) để tạo khối nhẹ
                    self.borderImageView.tintColor = self.mainColor.darker(by: 20) ?? .gray
                    
                    // 2. Cell bung ra full (Không padding)
                    // Vì Border nằm trên nên nó sẽ viền xung quanh Cell rất đẹp
                    self.topConstraint.constant = 0
                    self.bottomConstraint.constant = 0
                    self.leadingConstraint.constant = 0
                    self.trailingConstraint.constant = 0
                }
                self.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Pixel Plus Button (Nút CỘNG)
    class PixelPlusButton: UIButton {
        
        // LAYER 1: Nền (Dưới)
        private let bgImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.backgroundColor = .clear
            iv.isUserInteractionEnabled = false
            if let img = UIImage(named: "cell") {
                iv.image = img.withRenderingMode(.alwaysTemplate)
            }
            return iv
        }()
        
        // LAYER 2: Viền Asset (Trên)
        private let borderImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.backgroundColor = .clear
            iv.isUserInteractionEnabled = false
            if let img = UIImage(named: "border") {
                iv.image = img.withRenderingMode(.alwaysTemplate)
            }
            return iv
        }()
        
        // LAYER 3: Icon
        private let plusIconView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            iv.isUserInteractionEnabled = false
            if let img = UIImage(named: "plusImage") {
                iv.image = img
            } else {
                let config = UIImage.SymbolConfiguration(weight: .bold)
                iv.image = UIImage(systemName: "plus", withConfiguration: config)
            }
            iv.tintColor = UIColor(hex: "#27A7FF")
            return iv
        }()
        
        private var topConstraint: NSLayoutConstraint!
        private var bottomConstraint: NSLayoutConstraint!
        private var leadingConstraint: NSLayoutConstraint!
        private var trailingConstraint: NSLayoutConstraint!
        
        init() {
            super.init(frame: .zero)
            self.backgroundColor = .clear
            
            // 1. Add Cell
            addSubview(bgImageView)
            bgImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // 2. Add Border (Đè lên Cell)
            addSubview(borderImageView)
            borderImageView.translatesAutoresizingMaskIntoConstraints = false
            
            // Constraints cho Border
            NSLayoutConstraint.activate([
                borderImageView.topAnchor.constraint(equalTo: topAnchor),
                borderImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                borderImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                borderImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
            
            // Constraints cho Cell
            topConstraint = bgImageView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
            bottomConstraint = bgImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
            leadingConstraint = bgImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
            trailingConstraint = bgImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
            NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
            
            // 3. Add Icon
            addSubview(plusIconView)
            plusIconView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                plusIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
                plusIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
                plusIconView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
                plusIconView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
            ])
            
            reset() // Set trạng thái ban đầu
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        func reset() {
            UIView.animate(withDuration: 0.2) {
                self.plusIconView.alpha = 1.0
                
                // Viền màu xám khi chưa chọn
                self.borderImageView.tintColor = .systemGray3
                
                self.bgImageView.tintColor = .white
                
                // Full size
                self.topConstraint.constant = 0
                self.bottomConstraint.constant = 0
                self.leadingConstraint.constant = 0
                self.trailingConstraint.constant = 0
                
                self.layoutIfNeeded()
            }
        }
        
        func setSelectedColor(_ color: UIColor) {
            UIView.animate(withDuration: 0.2) {
                self.plusIconView.alpha = 0.0
                
                // Viền đậm theo màu
                self.borderImageView.tintColor = color.darker(by: 50) ?? .black
                
                self.bgImageView.tintColor = color
                
                // Zoom in
                let padding: CGFloat = 6
                self.topConstraint.constant = padding
                self.bottomConstraint.constant = -padding
                self.leadingConstraint.constant = padding
                self.trailingConstraint.constant = -padding
                
                self.layoutIfNeeded()
            }
        }
    }

    // MARK: - Helper Buttons & Main VC
    class PillGradientButton: UIButton {
        private let gradientLayer = CAGradientLayer()
        init(colors: [UIColor]) {
            super.init(frame: .zero)
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            layer.insertSublayer(gradientLayer, at: 0)
        }
        required init?(coder: NSCoder) { fatalError() }
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = bounds
            let radius = bounds.height / 2
            layer.cornerRadius = radius
            gradientLayer.cornerRadius = radius
        }
    }

    weak var delegate: BackgroundSelectionDelegate?
    
    private var selectedColor: UIColor?
    private let colors: [String] = ["#A3A877", "#FAD088", "#F29897", "#98F5FF", "#CCFF99", "#FFFFA5"]
    private var colorButtons: [PixelColorButton] = []
    
    private let customColorButton = PixelPlusButton()
    
    // UI Components
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return v
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "SELECT BACKGROUND"
        l.font = .systemFont(ofSize: 20, weight: .heavy)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose Color"
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = .black
        l.textAlignment = .left
        return l
    }()
    
    private let colorStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()
    
    private let cancelButton: PillGradientButton = {
        let b = PillGradientButton(colors: [UIColor(hex: "#5AC8FA"), UIColor(hex: "#27A7FF")])
        b.setTitle("Cancel", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 16)
        b.setTitleColor(.white, for: .normal)
        return b
    }()
    
    private let saveButton: PillGradientButton = {
        let b = PillGradientButton(colors: [UIColor(hex: "#5856D6"), UIColor(hex: "#7A70FF")])
        b.setTitle("Save", for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 16)
        b.setTitleColor(.white, for: .normal)
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(dimView)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        [titleLabel, subtitleLabel, colorStackView, cancelButton, saveButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        setupColorButtons()
        
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 340),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 25),
            
            colorStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 15),
            colorStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 25),
            colorStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -25),
            colorStackView.heightAnchor.constraint(equalToConstant: 40),
            
            cancelButton.topAnchor.constraint(equalTo: colorStackView.bottomAnchor, constant: 35),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 25),
            cancelButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.42),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -25),
            
            saveButton.topAnchor.constraint(equalTo: colorStackView.bottomAnchor, constant: 35),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -25),
            saveButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.42),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -25)
        ])
    }
    
    private func setupColorButtons() {
        for (index, hex) in colors.enumerated() {
            let color = UIColor(hex: hex)
            let btn = PixelColorButton(color: color)
            btn.tag = index
            btn.addTarget(self, action: #selector(didTapColor(_:)), for: .touchUpInside)
            colorStackView.addArrangedSubview(btn)
            colorButtons.append(btn)
        }
        
        customColorButton.addTarget(self, action: #selector(didTapCustomColor), for: .touchUpInside)
        customColorButton.translatesAutoresizingMaskIntoConstraints = false
        customColorButton.widthAnchor.constraint(equalTo: customColorButton.heightAnchor).isActive = true
        colorStackView.addArrangedSubview(customColorButton)
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCancel))
        dimView.addGestureRecognizer(tap)
    }
    
    @objc private func didTapColor(_ sender: PixelColorButton) {
        resetSelectionState()
        sender.isSelected = true
        let hex = colors[sender.tag]
        self.selectedColor = UIColor(hex: hex)
    }
    
    @objc private func didTapCustomColor() {
        let picker = UIColorPickerViewController()
        picker.delegate = self
        picker.modalPresentationStyle = .popover
        present(picker, animated: true)
    }
    
    private func resetSelectionState() {
        colorButtons.forEach { $0.isSelected = false }
        customColorButton.reset()
    }
    
    @objc private func didTapCancel() {
        dismiss(animated: true)
    }
    
    @objc private func didTapSave() {
        if let col = selectedColor {
            delegate?.didSelectBackgroundColor(col)
        }
        dismiss(animated: true)
    }
}

// MARK: - UIColorPicker Delegate
extension BackgroundSelectionViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        resetSelectionState()
        customColorButton.setSelectedColor(color)
        self.selectedColor = color
    }
}
