import HeroKit
import UIKit

protocol HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithHeaderStyle: HeroHeader.Style
    )
}

class HeaderPickerController: UIViewController, UICollectionViewDelegate {

    let navbarStyle: HeroHeader.Style
    var delegate: HeaderPickerControllerDelegate?

    init(navbarStyle: HeroHeader.Style) {
        self.navbarStyle = navbarStyle
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
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

    override func viewDidLoad() {
        title = "Color Collection"
        /*
         super.viewDidLoad()
         if #available(iOS 26, *) {
             navigationItem.largeTitle = "Large Title"
             navigationItem.title = "Normal Title"
         } else {
             title = "Color Collection"
         }
         */
        // view.backgroundColor = .systemBackground
        setupCollectionView()
        applySnapshot()
        try? configureHeader(navbarStyle)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let color = UIColor(red: item.red, green: item.green, blue: item.blue, alpha: 1.0)
        let style = HeroHeader.Style.color(backgroundColor: color, foregroundColor: .white)
        delegate?.headerPicker(self, didPickCellWithHeaderStyle: style)
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

    private let colors: [ColorItem] = [
        ColorItem(name: "Red", red: 1.0, green: 0.23, blue: 0.19),
        ColorItem(name: "Orange", red: 1.0, green: 0.58, blue: 0.0),
        ColorItem(name: "Yellow", red: 1.0, green: 0.8, blue: 0.0),
        ColorItem(name: "Green", red: 0.2, green: 0.78, blue: 0.35),
        ColorItem(name: "Mint", red: 0.0, green: 0.78, blue: 0.75),
    ]

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
