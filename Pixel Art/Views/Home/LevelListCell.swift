import UIKit

class LevelListCell: UICollectionViewCell {
    
    // 1. Container chính (Khung bo tròn)
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        
        // Đổ bóng màu xanh (#3475CB)
        v.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 8
        return v
    }()
    
    // 2. Ảnh hiển thị Pixel Art
    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor(hex: "#F5F5F5")
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        return iv
    }()
    
    // 3. Tên Level
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .black
        l.textAlignment = .left
        l.numberOfLines = 1
        return l
    }()
    
    // 4. Nhãn "New"
    private let newBadgeLabel: UILabel = {
        let l = UILabel()
        l.text = "New"
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.textColor = UIColor(hex: "#007AFF") // Màu xanh dương sáng
        l.isHidden = true // Mặc định ẩn
        return l
    }()
    
    // 5. Lớp phủ màu đen (Hiện khi bị khóa)
    private let lockOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.isHidden = true
        return v
    }()
    
    // 6. Icon Ổ khóa
    private let lockIcon: UIImageView = {
        let iv = UIImageView()
        if let img = UIImage(named: "lockIcon") {
            iv.image = img
        } else {
            iv.image = UIImage(systemName: "lock.fill")
        }
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    // Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // Setup Layout
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(previewImageView)
        containerView.addSubview(lockOverlay)
        containerView.addSubview(lockIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(newBadgeLabel)
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        lockOverlay.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        newBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Ảnh (Chiếm phần trên)
            previewImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            previewImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            previewImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            previewImageView.heightAnchor.constraint(equalTo: containerView.widthAnchor, constant: -16),
            
            // Nhãn "New" (Góc dưới phải)
            newBadgeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            newBadgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Tên Level (Góc dưới trái)
            nameLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: newBadgeLabel.leadingAnchor, constant: -8),
            
            // Lock Overlay & Icon
            lockOverlay.topAnchor.constraint(equalTo: previewImageView.topAnchor),
            lockOverlay.leadingAnchor.constraint(equalTo: previewImageView.leadingAnchor),
            lockOverlay.trailingAnchor.constraint(equalTo: previewImageView.trailingAnchor),
            lockOverlay.bottomAnchor.constraint(equalTo: previewImageView.bottomAnchor),
            
            lockIcon.centerXAnchor.constraint(equalTo: lockOverlay.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockOverlay.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 32),
            lockIcon.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // Configure Data
    func configure(level: LevelData) {
        nameLabel.text = level.name
        
        // 1. Vẽ hình preview
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = self?.drawPreview(from: level)
            DispatchQueue.main.async {
                self?.previewImageView.image = image
            }
        }
        
        // 2. Logic Khóa
        let isUnlockedLocally = GameStorageManager.shared.isLevelUnlocked(id: level.id)
        let isActuallyLocked = level.isLocked && !isUnlockedLocally
        
        lockOverlay.isHidden = !isActuallyLocked
        lockIcon.isHidden = !isActuallyLocked
        
        // 3. Logic hiển thị chữ "New"
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        let timeDiff = Date().timeIntervalSince(level.createdAt)
        
        if timeDiff < oneDayInSeconds {
            newBadgeLabel.isHidden = false
        } else {
            newBadgeLabel.isHidden = true
        }
        
        containerView.layer.borderColor = UIColor.white.cgColor
    }
    
    private func drawPreview(from level: LevelData) -> UIImage? {
        let size = CGSize(width: level.gridWidth, height: level.gridHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Vẽ nền trắng
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            for pixel in level.pixels {
                if pixel.number == 0 { continue }
                
                let colorIndex = pixel.number - 1
                if colorIndex >= 0 && colorIndex < level.paletteModels.count {
                    var uiColor = level.paletteModels[colorIndex].toUIColor
                    
                    if !pixel.isColored {
                        uiColor = uiColor.withAlphaComponent(0.1)
                    }
                    
                    ctx.setFillColor(uiColor.cgColor)
                    ctx.fill(CGRect(x: pixel.x, y: pixel.y, width: 1, height: 1))
                }
            }
        }
    }
}
