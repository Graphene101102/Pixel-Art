import UIKit

class GalleryViewController: UIViewController {

    // MARK: - Properties
    private var levels: [LevelData] = []
    
    // MARK: - UI Elements
    // Nền BG giống Home
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Gallery"
        l.font = .systemFont(ofSize: 32, weight: .black)
        l.textColor = .black
        return l
    }()
    
    private var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadData),
            name: NSNotification.Name("DidUpdateLevelProgress"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadData()
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: - Data Logic
    @objc private func loadData() {
        // Load Local, Không gom nhóm
        self.levels = GameStorageManager.shared.loadAllLocalLevels()
        self.collectionView.reloadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 1. Thêm Background
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        // 2. Title
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. CollectionView (Hình vuông)
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 17
        let itemWidth = (view.frame.width - (padding * 2) - 10) / 2
        // [SỬA] Height = Width (Hình vuông)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 10, left: padding, bottom: 100, right: padding)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(LevelListCell.self, forCellWithReuseIdentifier: "LevelListCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func startGame(level: LevelData) {
        let vm = GameViewModel(level: level)
        let vc = GameViewController(viewModel: vm)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

// MARK: - CollectionView Delegate
extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return levels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LevelListCell", for: indexPath) as! LevelListCell
        // [QUAN TRỌNG] Chế độ .progress để tô nhạt phần chưa tô
        cell.configure(level: levels[indexPath.item], mode: .progress)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = levels[indexPath.item]
        startGame(level: level)
    }
}
