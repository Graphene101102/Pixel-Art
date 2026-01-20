import UIKit

// Enum để xác định cách vẽ preview
enum LevelRenderMode {
    case fullPreview // Home: Vẽ full màu
    case progress    // Gallery: Vẽ theo tiến độ (tô mờ/đậm)
}

class LevelListCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        // Shadow nhẹ
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 6
        return v
    }()
    
    // View vẽ Pixel
    private let previewView = LevelPreviewView()
    
    // Icon khóa (Chỉ hiện ở Home nếu bị khóa)
    private let lockIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "lock.fill"))
        iv.tintColor = .white
        iv.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        iv.contentMode = .center
        iv.layer.cornerRadius = 15
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    
    // [MỚI] Nhãn NEW (Thay thế cho Checkmark)
    private let newLabel: UILabel = {
        let l = UILabel()
        l.text = "NEW"
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor.red
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.clipsToBounds = true
        l.isHidden = true
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(previewView)
        containerView.addSubview(lockIcon)
        containerView.addSubview(newLabel) // Thêm label NEW
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        newLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container hình vuông
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Preview nằm gọn bên trong
            previewView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            previewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // Lock icon giữa hình
            lockIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 30),
            lockIcon.heightAnchor.constraint(equalToConstant: 30),
            
            // [MỚI] New Label: Góc trên phải (hoặc trái tùy bạn, ở đây để góc trên phải cho nổi)
            newLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            newLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            newLabel.widthAnchor.constraint(equalToConstant: 36),
            newLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func configure(level: LevelData, mode: LevelRenderMode) {
        // Cập nhật mode vẽ
        previewView.renderMode = mode
        previewView.level = level
        previewView.setNeedsDisplay()
        
        if mode == .fullPreview {
            // --- HOME VIEW CONFIG ---
            
            // 1. Xử lý Lock
            lockIcon.isHidden = !level.isLocked
            previewView.alpha = level.isLocked ? 0.3 : 1.0
            
            // 2. Xử lý nhãn NEW
            // Hiện NEW nếu: Không bị khóa VÀ Chưa chơi (timeSpent == 0)
            if !level.isLocked && level.timeSpent == 0 {
                newLabel.isHidden = false
            } else {
                newLabel.isHidden = true
            }
            
        } else {
            // --- GALLERY VIEW CONFIG ---
            
            // Luôn ẩn Lock và New ở Gallery
            lockIcon.isHidden = true
            newLabel.isHidden = true
            previewView.alpha = 1.0
        }
    }
}

// MARK: - Class Vẽ Pixel (Giữ nguyên logic tô đậm/nhạt)
class LevelPreviewView: UIView {
    var level: LevelData?
    var renderMode: LevelRenderMode = .fullPreview
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ rect: CGRect) {
        guard let level = level, let context = UIGraphicsGetCurrentContext() else { return }
        
        let gridW = CGFloat(level.gridWidth)
        let gridH = CGFloat(level.gridHeight)
        if gridW == 0 || gridH == 0 { return }
        
        let scale = min(rect.width / gridW, rect.height / gridH)
        let pixelSize = scale
        
        let offsetX = (rect.width - (gridW * scale)) / 2
        let offsetY = (rect.height - (gridH * scale)) / 2
        
        for pixel in level.pixels {
            if pixel.number > 0 {
                let x = offsetX + CGFloat(pixel.x) * pixelSize
                let y = offsetY + CGFloat(pixel.y) * pixelSize
                let pixelRect = CGRect(x: x, y: y, width: pixelSize, height: pixelSize)
                
                let baseColor = pixel.rawColor.toUIColor
                
                if renderMode == .fullPreview {
                    // Home: Luôn tô đậm
                    baseColor.setFill()
                    context.fill(pixelRect)
                } else {
                    // Gallery: Tô đậm nếu đã colored, nhạt nếu chưa
                    if pixel.isColored {
                        baseColor.setFill()
                        context.fill(pixelRect)
                    } else {
                        baseColor.withAlphaComponent(0.15).setFill()
                        context.fill(pixelRect)
                    }
                }
            }
        }
    }
}
