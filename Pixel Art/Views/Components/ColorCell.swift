import UIKit

class ColorCell: UICollectionViewCell {
    
    private let numberLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 25
        contentView.clipsToBounds = true
        
        // Setup Label số
        numberLabel.font = .boldSystemFont(ofSize: 14)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(numberLabel)
        
        // 2. Setup Checkmark Icon
        let checkImage = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.image = checkImage
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.backgroundColor = .white
        checkmarkImageView.layer.cornerRadius = 10
        checkmarkImageView.clipsToBounds = true
        checkmarkImageView.isHidden = true // Mặc định ẩn
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            // Label căn giữa
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Checkmark căn giữa
            checkmarkImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(color: UIColor, number: Int, isSelected: Bool, isCompleted: Bool) {
        contentView.backgroundColor = color
        
        if isCompleted {
            // --- TRẠNG THÁI HOÀN THÀNH ---
            numberLabel.isHidden = true
            checkmarkImageView.isHidden = false
            
            // Viền xanh lá
            contentView.layer.borderColor = UIColor.systemGreen.cgColor
            contentView.layer.borderWidth = 3.0
            
            transform = .identity
            
        } else {
            // --- TRẠNG THÁI CHƯA XONG ---
            numberLabel.isHidden = false
            checkmarkImageView.isHidden = true
            numberLabel.text = "\(number)"
            
            // Kiểm tra màu tương phản để hiện số
            numberLabel.layer.shadowColor = UIColor.black.cgColor
            numberLabel.layer.shadowOpacity = 0.5
            numberLabel.layer.shadowRadius = 1
            numberLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
            
            if isSelected {
                contentView.layer.borderWidth = 4
                contentView.layer.borderColor = UIColor.blue.cgColor
                transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                contentView.layer.borderWidth = 1
                contentView.layer.borderColor = UIColor.lightGray.cgColor
                transform = .identity
            }
        }
    }
}
