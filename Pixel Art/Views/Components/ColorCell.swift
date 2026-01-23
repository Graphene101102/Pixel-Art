import UIKit

// MARK: - Updated Extension
extension UIColor {
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    // SỬA LẠI: Tính độ sáng dựa trên công thức Luminance chuẩn để chính xác hơn
    func isLight() -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // Công thức tính độ sáng: (0.299 * R + 0.587 * G + 0.114 * B)
            let brightness = (red * 0.299) + (green * 0.587) + (blue * 0.114)
            return brightness > 0.6 // Ngưỡng > 0.6 là màu sáng (có thể chỉnh 0.5 tuỳ mắt nhìn)
        }
        return false
    }
    
    func isNearWhite() -> Bool {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                let brightness = (red * 0.299) + (green * 0.587) + (blue * 0.114)
                return brightness > 0.9 // Ngưỡng 0.9 (gần 1.0) là rất sáng/trắng
            }
            return false
        }
    
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        }
        return nil
    }
}

// MARK: - Color Cell
class ColorCell: UICollectionViewCell {
    
    private let numberLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        
        contentView.layer.cornerRadius = 25
        contentView.clipsToBounds = true
        
        // Setup Label
        numberLabel.font = .boldSystemFont(ofSize: 14)
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(numberLabel)
        
        // Setup Checkmark
        if let checkImage = UIImage(named: "done")?.withRenderingMode(.alwaysTemplate) {
            checkmarkImageView.image = checkImage
        } else {
            checkmarkImageView.image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        }
        
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            checkmarkImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 28),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(color: UIColor, number: Int, isSelected: Bool, isCompleted: Bool) {
        
        // Reset state
        self.layer.shadowOpacity = 0
        self.layer.shadowOffset = .zero
        self.transform = .identity
        contentView.layer.borderWidth = 0
        
        if isCompleted {
            // --- ĐÃ HOÀN THÀNH ---
            contentView.backgroundColor = color.withAlphaComponent(0.3)
            numberLabel.isHidden = true
            checkmarkImageView.isHidden = false
            
            if color.isNearWhite() {
                // Nếu màu là trắng hoặc gần trắng
                checkmarkImageView.tintColor = .black
            } else {
                // Nếu các màu khác
                checkmarkImageView.tintColor = color
            }
            
            contentView.layer.borderColor = UIColor.systemGray5.cgColor
            contentView.layer.borderWidth = 1.0
            
        } else {
            // --- CHƯA HOÀN THÀNH ---
            numberLabel.isHidden = false
            checkmarkImageView.isHidden = true
            numberLabel.text = "\(number)"
            contentView.backgroundColor = color
            
            // [YÊU CẦU 2]: Xử lý màu chữ Đen/Trắng dựa trên độ sáng màu nền
            if color.isLight() {
                numberLabel.textColor = .black
                // Nếu chữ màu đen thì tắt shadow của chữ đi cho đỡ rối
                numberLabel.layer.shadowOpacity = 0
            } else {
                numberLabel.textColor = .white
                // Nếu chữ trắng thì thêm shadow đen nhẹ để nổi bật trên nền sáng vừa
                numberLabel.layer.shadowColor = UIColor.black.cgColor
                numberLabel.layer.shadowOpacity = 0.3
                numberLabel.layer.shadowRadius = 1
                numberLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
            }
            
            if isSelected {
                // --- ĐANG CHỌN (Hiệu ứng 3D) ---
                contentView.layer.borderWidth = 2
                contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
                
                // Shadow cho Cell
                self.layer.shadowColor = color.darker(by: 40)?.cgColor ?? UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 6)
                self.layer.shadowRadius = 0
                self.layer.shadowOpacity = 1.0
                self.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 25).cgPath
                
                transform = CGAffineTransform(translationX: 0, y: -2)
                
            } else {
                // --- KHÔNG CHỌN (Bình thường) ---
                // [YÊU CẦU 1]: Thêm border màu xám
                contentView.layer.borderWidth = 1.5 // Viền mỏng hơn khi chọn
                contentView.layer.borderColor = UIColor.systemGray4.cgColor // Màu xám nhạt
            }
        }
    }
}
