import UIKit

class FreeStyleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Chế độ Tô màu"
        
        let label = UILabel()
        label.text = "Trang vẽ trống \n"
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 20)
        label.center = view.center
        view.addSubview(label)
    }
}
