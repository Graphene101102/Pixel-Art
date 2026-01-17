import UIKit

class LevelListCell: UICollectionViewCell {
    
    // --- UI Elements ---
    
    // 1. Container (Khung thẻ bài)
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        // Bo góc mềm mại
        v.layer.cornerRadius = 20
        
        // [ĐÃ SỬA] Viền màu #130F29
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor(hex: "#3475CB").cgColor
        
        v.layer.shadowColor = UIColor(hex: "#3475CB").cgColor
        v.layer.shadowOpacity = 0.25
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 4
        return v
    }()
    
    // 2. Preview Canvas (Ảnh Pixel)
    private let previewView: CanvasView = {
        let cv = CanvasView()
        cv.backgroundColor = .clear
        cv.layer.cornerRadius = 16 
        cv.clipsToBounds = true
        cv.isUserInteractionEnabled = false
        return cv
    }()
    
    // 3. Name Label (Tên)
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .bold) 
        lbl.textColor = .black
        lbl.textAlignment = .left
        return lbl
    }()
    
    // 4. New Badge (Nhãn Mới)
    private let newBadgeLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "New"
        lbl.font = .systemFont(ofSize: 12, weight: .bold)
        // Giữ màu xanh sáng cho nổi bật (hoặc đổi thành #130F29 nếu bạn muốn đồng bộ hết)
        lbl.textColor = UIColor(hex: "#3475CB")
        lbl.isHidden = true
        return lbl
    }()
    
    // --- Init ---
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // --- Layout ---
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        // Add Subviews
        contentView.addSubview(containerView)
        containerView.addSubview(previewView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(newBadgeLabel)
        
        // Disable AutoResizingMask
        [containerView, previewView, nameLabel, newBadgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Constraints
        // Note: Cấu trúc này tạo ra thẻ đứng (ảnh vuông phía trên + text phía dưới)
        // Miễn là height được tính toán đúng trong HomeViewController.
        NSLayoutConstraint.activate([
            // 1. Container Full Cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 2. Preview Image (Chiếm phần trên, padding đều 12px)
            previewView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            // Bắt buộc ảnh luôn vuông
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor),
            
            // 3. Name Label (Dưới ảnh, bên trái)
            // Neo top vào đáy ảnh, neo bottom vào đáy container
            nameLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            // Giới hạn chiều rộng bên phải để không đè lên chữ New
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: newBadgeLabel.leadingAnchor, constant: -8),
            
            // 4. New Badge (Dưới ảnh, bên phải - Căn giữa theo chiều dọc với Tên)
            newBadgeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            newBadgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
        ])
    }
    
    // --- Configuration ---
    func configure(level: LevelData) {
        nameLabel.text = level.name
        
        // Logic New Badge (Dưới 24h)
        let oneDay: TimeInterval = 86400
        let isNew = Date().timeIntervalSince(level.createdAt) < oneDay
        newBadgeLabel.isHidden = !isNew
        
        // Render Canvas
        self.layoutIfNeeded()
        // currentNumber = -1 để hiển thị màu hoàn thiện
        previewView.render(level: level, currentNumber: -1)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        newBadgeLabel.isHidden = true
    }
}
