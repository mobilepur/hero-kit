import Combine
import HeroKit
import UIKit

class ViewController: UIViewController {

    private var scrollCancellable: AnyCancellable?

    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, ColorItem> = {
        let cellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            ColorItem
        > {
            cell, _, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.name
            let color = UIColor(red: item.red, green: item.green, blue: item.blue, alpha: 1.0)
            content.image = Self.colorImage(for: color)
            cell.contentConfiguration = content
        }

        return UICollectionViewDiffableDataSource<Int, ColorItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    }()

    private let colors: [ColorItem] = [
        ColorItem(name: "Red", red: 1.0, green: 0.23, blue: 0.19),
        ColorItem(name: "Orange", red: 1.0, green: 0.58, blue: 0.0),
        ColorItem(name: "Yellow", red: 1.0, green: 0.8, blue: 0.0),
        ColorItem(name: "Green", red: 0.2, green: 0.78, blue: 0.35),
        ColorItem(name: "Mint", red: 0.0, green: 0.78, blue: 0.75),
        ColorItem(name: "Teal", red: 0.19, green: 0.69, blue: 0.78),
        ColorItem(name: "Cyan", red: 0.31, green: 0.69, blue: 0.87),
        ColorItem(name: "Blue", red: 0.0, green: 0.48, blue: 1.0),
        ColorItem(name: "Indigo", red: 0.35, green: 0.34, blue: 0.84),
        ColorItem(name: "Purple", red: 0.69, green: 0.32, blue: 0.87),
        ColorItem(name: "Pink", red: 1.0, green: 0.18, blue: 0.33),
        ColorItem(name: "Brown", red: 0.64, green: 0.52, blue: 0.37),
        ColorItem(name: "Gray", red: 0.56, green: 0.56, blue: 0.58),
        ColorItem(name: "Dark Gray", red: 0.33, green: 0.33, blue: 0.33),
        ColorItem(name: "Light Gray", red: 0.67, green: 0.67, blue: 0.67),
        ColorItem(name: "Black", red: 0.0, green: 0.0, blue: 0.0),
        ColorItem(name: "White", red: 1.0, green: 1.0, blue: 1.0),
        ColorItem(name: "Magenta", red: 1.0, green: 0.0, blue: 1.0),
        ColorItem(name: "Coral", red: 1.0, green: 0.5, blue: 0.31),
        ColorItem(name: "Lavender", red: 0.9, green: 0.9, blue: 0.98),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Color Collection"
        view.backgroundColor = .systemBackground
        setupCollectionView()
        applySnapshot()
        scrollCancellable = subscribeToScrollOffset(of: collectionView)
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ColorItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(colors)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private static func colorImage(for color: UIColor,
                                   size: CGSize = CGSize(width: 28, height: 28)) -> UIImage
    {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

nonisolated struct ColorItem: Sendable, Hashable {
    let id: UUID
    let name: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(name: String, red: CGFloat, green: CGFloat, blue: CGFloat) {
        id = UUID()
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
    }
}
