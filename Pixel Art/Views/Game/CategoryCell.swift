import UIKit

class CategoryCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 15
        contentView.layer.borderWidth = 1
        
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(text: String, isSelected: Bool) {
        label.text = text
        if isSelected {
            contentView.backgroundColor = UIColor(hex: "#3475CB")
            contentView.layer.borderColor = UIColor(hex: "#3475CB").cgColor
            label.textColor = .white
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = UIColor(hex: "#E0E0E0").cgColor
            label.textColor = UIColor(hex: "#828282")
        }
    }
    
    // Tự động tính toán kích thước cell dựa trên nội dung text
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: 35)
        let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required)
        attributes.frame.size = size
        return attributes
    }
}
