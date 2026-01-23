import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let headerView = UIView()
    private let titleLabel = UILabel()
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        let bgView = AppBackgroundView()
        view.addSubview(bgView)
        bgView.frame = view.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.sendSubviewToBack(bgView)
        
        // --- Header ---
        headerView.backgroundColor = .clear
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "SETTING"
        titleLabel.font = .systemFont(ofSize: 24, weight: .heavy)
        titleLabel.textColor = .black
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Content ---
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([   
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
        
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // StackView
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40) // Padding trái phải 20
        ])
    }
    
    private func setupContent() {
        // Section 1: Music & Sound
        let section1 = createSectionContainer()
        let musicRow = createToggleRow(icon: "music", title: "Music", isOn: SoundManager.shared.isMusicEnabled, tag: 0)
        let soundRow = createToggleRow(icon: "Sound fx", title: "Sound FX", isOn: SoundManager.shared.isHapticEnabled, tag: 1)
        section1.addArrangedSubview(musicRow)
        section1.addArrangedSubview(createSeparator())
        section1.addArrangedSubview(soundRow)
        
        
        // Section 2: General
        let section2 = createSectionContainer()
        let langRow = createNavRow(icon: "Translete", title: "Language", action: #selector(didTapLanguage))
        let shareRow = createNavRow(icon: "Share", title: "Share to your friends", action: #selector(didTapShare))
        let rateRow = createNavRow(icon: "rate", title: "Rate 5 stars", action: #selector(didTapRate))
        let feedbackRow = createNavRow(icon: "Feedback", title: "Feedback", action: #selector(didTapFeedback))
        
        section2.addArrangedSubview(langRow)
        section2.addArrangedSubview(createSeparator())
        section2.addArrangedSubview(shareRow)
        section2.addArrangedSubview(createSeparator())
        section2.addArrangedSubview(rateRow)
        section2.addArrangedSubview(createSeparator())
        section2.addArrangedSubview(feedbackRow)
        
        // Section 3: Info
        let section3 = createSectionContainer()
        let policyRow = createNavRow(icon: "Policy", title: "Policy", action: #selector(didTapPolicy))
        let cmpRow = createNavRow(icon: "Frame", title: "Cmp setting", action: #selector(didTapCmp))
        let updateRow = createNavRow(icon: "Update", title: "Check for update", action: #selector(didTapUpdate))
        
        section3.addArrangedSubview(policyRow)
        section3.addArrangedSubview(createSeparator())
        section3.addArrangedSubview(cmpRow)
        section3.addArrangedSubview(createSeparator())
        section3.addArrangedSubview(updateRow)
        
        // Add to Main Stack
        stackView.addArrangedSubview(section1)
        stackView.addArrangedSubview(section2)
        stackView.addArrangedSubview(section3)
    }
    
    // MARK: - Helper Methods (Builders)
    
    // Tạo Container trắng bo góc (Card)
    private func createSectionContainer() -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 0
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        
        container.layer.masksToBounds = false
        
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.2
        container.layer.shadowOffset = CGSize(width: 1, height: 4)
        container.layer.shadowRadius = 12
        
        return container
    }
    
    // Tạo dòng kẻ ngang
    private func createSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray5
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }
    
    // Tạo Row có Switch (Music/Sound)
    private func createToggleRow(icon: String, title: String, isOn: Bool, tag: Int) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let iconView = UIImageView()
        iconView.image = UIImage(named: icon) ?? UIImage(systemName: "gear") // Fallback
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(hex: "#3475CB") // Màu icon xanh (nếu là template image)
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        
        let switchControl = UISwitch()
        switchControl.isOn = isOn
        switchControl.onTintColor = UIColor(hex: "#3475CB") // Màu xanh khi bật
        switchControl.tag = tag
        switchControl.addTarget(self, action: #selector(didToggleSwitch(_:)), for: .valueChanged)
        
        [iconView, label, switchControl].forEach {
            row.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        
        return row
    }
    
    // Tạo Row có mũi tên điều hướng
    private func createNavRow(icon: String, title: String, action: Selector) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Tap Gesture
        let tap = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true
        
        let iconView = UIImageView()
        iconView.image = UIImage(named: icon) ?? UIImage(systemName: "star")
        iconView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .gray
        
        [iconView, label, arrow].forEach {
            row.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            
            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 12),
            arrow.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return row
    }
    
    // Copy helper config button từ các file cũ
    private func configureSquareButton(_ btn: UIButton, iconName: String) {
        if let image = UIImage(named: iconName) {
            btn.setImage(image, for: .normal)
        } else {
            btn.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        }
        btn.tintColor = UIColor(hex: "#3475CB")
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(hex: "#3475CB").withAlphaComponent(0.3).cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Actions
    @objc private func didTapBack() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func didToggleSwitch(_ sender: UISwitch) {
            if sender.tag == 0 {
                // Music: Cập nhật thẳng vào Singleton
                SoundManager.shared.isMusicEnabled = sender.isOn
            } else {
                // Sound FX: Cập nhật thẳng vào Singleton
                SoundManager.shared.isHapticEnabled = sender.isOn
            }
        }
    
    // Placeholder Actions
    @objc private func didTapLanguage() { print("Language tapped") }
    @objc private func didTapShare() { print("Share tapped") }
    @objc private func didTapRate() { print("Rate tapped") }
    @objc private func didTapFeedback() { print("Feedback tapped") }
    @objc private func didTapPolicy() { print("Policy tapped") }
    @objc private func didTapCmp() { print("Cmp tapped") }
    @objc private func didTapUpdate() { print("Update tapped") }
}
