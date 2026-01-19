import UIKit

protocol BackgroundSelectionDelegate: AnyObject {
    func didSelectBackgroundColor(_ color: UIColor)
}

class BackgroundSelectionViewController: UIViewController {
    
    weak var delegate: BackgroundSelectionDelegate?
    
    // MARK: - State
    private var selectedColor: UIColor?
    
    // Màu mẫu cố định
    private let colors: [String] = ["#A3A877", "#FAD088", "#F29897", "#98F5FF", "#CCFF99", "#D0D0D0"]
    private var colorButtons: [UIButton] = []
    
    //Custom Color
    private let customColorButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "plus"), for: .normal)
        btn.tintColor = .systemBlue
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 4
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.lightGray.cgColor
        return btn
    }()
    
    // MARK: - UI Elements
    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return v
    }()
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = true
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "SELECT BACKGROUND"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Choose Color"
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .black
        l.textAlignment = .left
        return l
    }()
    
    // Stack chứa các ô màu + nút cộng
    private let colorStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.spacing = 10
        return s
    }()
    
    private let cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hex: "#5AC8FA")
        b.layer.cornerRadius = 20
        return b
    }()
    
    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(hex: "#5856D6")
        b.layer.cornerRadius = 20
        return b
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup UI
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
            // Dim View
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            // Chiều cao sẽ tự động tính theo nội dung bên trong
            
            // Layout bên trong
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            colorStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 15),
            colorStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            colorStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            colorStackView.heightAnchor.constraint(equalToConstant: 30), 
            
            cancelButton.topAnchor.constraint(equalTo: colorStackView.bottomAnchor, constant: 30),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: colorStackView.bottomAnchor, constant: 30),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupColorButtons() {
        for (index, hex) in colors.enumerated() {
            let btn = UIButton()
            btn.backgroundColor = UIColor(hex: hex)
            btn.layer.cornerRadius = 8 // Bo góc mềm hơn chút
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.lightGray.cgColor
            btn.tag = index
            btn.addTarget(self, action: #selector(didTapColor(_:)), for: .touchUpInside)
            colorStackView.addArrangedSubview(btn)
            colorButtons.append(btn)
        }
        customColorButton.addTarget(self, action: #selector(didTapCustomColor), for: .touchUpInside)
        customColorButton.layer.cornerRadius = 8
        colorStackView.addArrangedSubview(customColorButton)
    }
    
    // MARK: - Actions
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCancel))
        dimView.addGestureRecognizer(tap)
    }
    
    @objc private func didTapColor(_ sender: UIButton) {
        resetSelectionState()
        
        sender.layer.borderWidth = 3
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        
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
        colorButtons.forEach { $0.layer.borderWidth = 1; $0.layer.borderColor = UIColor.lightGray.cgColor }
        customColorButton.layer.borderWidth = 1
        customColorButton.layer.borderColor = UIColor.lightGray.cgColor
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
        
        customColorButton.backgroundColor = color
        customColorButton.tintColor = (color.isLight() ?? true) ? .black : .white
        customColorButton.layer.borderWidth = 3
        customColorButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        self.selectedColor = color
    }
}

// MARK: - Extension Helper
extension UIColor {

    func isLight() -> Bool? {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.5
    }
}
