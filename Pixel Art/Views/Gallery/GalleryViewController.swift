import UIKit

class GalleryViewController: UIViewController {

    // Data: Chứa các level ĐANG TÔ (ít nhất 1 pixel màu)
    private var localLevels: [LevelData] = []

    // MARK: - UI Elements
    
    // 1. Ảnh nền toàn màn hình (BG)
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "BG")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Gallery"
        l.font = .systemFont(ofSize: 24, weight: .medium)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()
    
    private var collectionView: UICollectionView!
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No started artworks yet."
        l.numberOfLines = 2
        l.textAlignment = .center
        l.textColor = .gray
        l.isHidden = true
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadLocalLevels() 
    }

    private func setupUI() {
        view.backgroundColor = .white
        
        // Background
        view.addSubview(backgroundImageView)
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(titleLabel)
        view.addSubview(emptyLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout CollectionView
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 20
        let itemWidth = (view.frame.width - (padding * 3)) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.sectionInset = UIEdgeInsets(top: 30, left: 20, bottom: 100, right: 20)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // CollectionView
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty Label
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - [LOGIC MỚI] Chỉ load Level Local ĐÃ BẮT ĐẦU TÔ
    private func loadLocalLevels() {
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [LevelData] = []
            let fileManager = FileManager.default
            
            // 1. Tìm đường dẫn thư mục Documents
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            do {
                // 2. Lấy danh sách tất cả các file
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey])
                
                // 3. Lọc ra các file json bắt đầu bằng "progress_"
                let saveFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("progress_") && $0.pathExtension == "json" }
                
                for url in saveFiles {
                    // 4. Đọc và Decode file
                    if let data = try? Data(contentsOf: url),
                       let level = try? JSONDecoder().decode(LevelData.self, from: data) {
                        
                        results.append(level)
                    }
                }
                
        // 6. Sắp xếp: Cái nào mới lưu gần đây nhất lên đầu (theo ngày tạo file gốc hoặc ngày chỉnh sửa)
        // Ở đây dùng createdAt của level để sắp xếp
        results.sort(by: { $0.createdAt > $1.createdAt })
                
            } catch {
                print("Error loading started levels: \(error)")
            }
            
            DispatchQueue.main.async {
                self.localLevels = results
                self.collectionView.reloadData()
                self.emptyLabel.isHidden = !results.isEmpty
                
                if results.isEmpty {
                    self.emptyLabel.text = "No started artworks yet.\nGo to Library and pick one!"
                }
            }
        }
    }
}

// MARK: - CollectionView Delegate & DataSource
extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localLevels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        cell.configure(level: localLevels[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let level = localLevels[indexPath.item]
        let vm = GameViewModel(level: level)
        let vc = GameViewController(viewModel: vm)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
