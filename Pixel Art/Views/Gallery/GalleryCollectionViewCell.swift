import UIKit

class GalleryCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 3
        v.layer.borderColor = UIColor(hex: "#1A237E").cgColor
        v.clipsToBounds = true
        return v
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Full viền
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    func configure(level: LevelData) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let image = self?.drawPreview(from: level)
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
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
                    
                    // Logic mờ nếu chưa tô
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

