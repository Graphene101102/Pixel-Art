import UIKit

class LevelListCell: UICollectionViewCell {
    
    // 1. UI Elements
    private let previewView = CanvasView()
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // 2. Setup UI
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        // Cấu hình Canvas Preview
        previewView.backgroundColor = .clear
        previewView.layer.cornerRadius = 8
        previewView.clipsToBounds = true
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.isUserInteractionEnabled = false // Chặn tương tác để click được Cell
        contentView.addSubview(previewView)
        
        // Cấu hình Label
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            previewView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    // 3. Configure Data
    func configure(level: LevelData) {
        nameLabel.text = level.name
        
        self.layoutIfNeeded()
        previewView.layoutIfNeeded()
        
        previewView.render(level: level, currentNumber: -1)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
    }
}
