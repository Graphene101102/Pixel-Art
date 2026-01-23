import UIKit

class AppBackgroundView: UIView {

    // 1. Ghi đè layerClass để view này sử dụng CAGradientLayer làm layer chính
    override public class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    // 2. Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // 3. Cấu hình màu sắc
    private func setupGradient() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }

        // Màu trên: Trắng (#FFFFFF)
        // Màu dưới: Xanh nhạt (#CBE4FF)
        let topColor = UIColor(hex: "#FFFFFF").cgColor
        let bottomColor = UIColor(hex: "#CBE4FF").cgColor

        gradientLayer.colors = [topColor, bottomColor]

        // Hướng gradient: Từ trên xuống dưới
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)   
    }
}
