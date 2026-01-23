import UIKit

// Enum để xác định cách vẽ preview
enum LevelRenderMode {
    case fullPreview // Home: Vẽ full màu
    case progress    // Gallery: Vẽ theo tiến độ (tô mờ/đậm)
}

class LevelListCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor(hex: "#338CFF").cgColor
        v.layer.cornerRadius = 21
        
        // Shadow nhẹ
        v.layer.shadowColor = UIColor(hex: "#000000").cgColor
        v.layer.shadowOpacity = 0.25
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 6
        return v
    }()
    
    // View vẽ Pixel
    private let previewView = LevelPreviewView()
    
    // Nhãn NEW (Chỉ hiện nếu ngày tạo còn mới)
    private let newLabel: UILabel = {
        let l = UILabel()
        l.text = "NEW"
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = .white
        l.backgroundColor = UIColor(hex: "#338CFF")
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
        // [ĐÃ XÓA] lockIcon
        containerView.addSubview(newLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        previewView.translatesAutoresizingMaskIntoConstraints = false
        newLabel.translatesAutoresizingMaskIntoConstraints = false
        
        previewView.layer.cornerRadius = 19
        previewView.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            // Container hình vuông
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Preview nằm gọn bên trong
            previewView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            previewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
            previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            
            // New Label: Góc trên phải
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
            
            // 1. Luôn hiển thị rõ (không làm mờ nữa vì bỏ khóa)
            previewView.alpha = 1.0
            
            // 2. Logic hiển thị NEW theo ngày tạo
            let timeInterval = Date().timeIntervalSince(level.createdAt)
                        let isRecent = timeInterval < (3 * 24 * 60 * 60)
                        
                        if isRecent {
                            newLabel.isHidden = false
                        } else {
                            newLabel.isHidden = true
                        }
            
        } else {
            // --- GALLERY VIEW CONFIG ---
            newLabel.isHidden = true
            previewView.alpha = 1.0
        }
    }
}

// MARK: - Class Vẽ Pixel (Phải đặt ở đây để hết lỗi Scope)
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
