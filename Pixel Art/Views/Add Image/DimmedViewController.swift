import UIKit

class DimmedViewController: UIViewController {
    
    private let dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(dimmedBackgroundView)
        dimmedBackgroundView.frame = view.bounds
        dimmedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3) {
            self.dimmedBackgroundView.alpha = 0.5
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.3) {
            self.dimmedBackgroundView.alpha = 0
        }
    }
}
