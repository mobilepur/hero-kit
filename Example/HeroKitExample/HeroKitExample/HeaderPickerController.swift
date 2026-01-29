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
        config.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, StyleItem> = {
        let cellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            StyleItem
        > { cell, _, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.name
            content.image = item.image
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            content.imageProperties.cornerRadius = 6
            cell.contentConfiguration = content
        }

        let headerRegistration = UICollectionView
            .SupplementaryRegistration<UICollectionViewListCell>(
                elementKind: UICollectionView.elementKindSectionHeader
            ) { [weak self] headerView, _, indexPath in
                guard let section = self?.dataSource.sectionIdentifier(for: indexPath.section)
                else { return }
                var content = headerView.defaultContentConfiguration()
                content.text = section.title
                headerView.contentConfiguration = content
            }

        let dataSource = UICollectionViewDiffableDataSource<Section, StyleItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }

        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }

        return dataSource
    }()

    override func viewDidLoad() {
        title = "Style Picker"
        if #unavailable(iOS 26) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }

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
        delegate?.headerPicker(self, didPickCellWithHeaderStyle: item.style)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, StyleItem>()
        snapshot.appendSections([.colors, .views])
        snapshot.appendItems(colorItems, toSection: .colors)
        snapshot.appendItems(viewItems, toSection: .views)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Data

    private let colorItems: [StyleItem] = [
        .color(name: "Red", red: 1.0, green: 0.23, blue: 0.19),
        .color(name: "Orange", red: 1.0, green: 0.58, blue: 0.0),
        .color(name: "Yellow", red: 1.0, green: 0.8, blue: 0.0),
        .color(name: "Green", red: 0.2, green: 0.78, blue: 0.35),
        .color(name: "Mint", red: 0.0, green: 0.78, blue: 0.75),
    ]

    private let viewItems: [StyleItem] = [
        .headerView(assetName: "bikes", height: 200),
        .headerView(assetName: "ricefields", height: 200),
        .headerView(assetName: "temple", height: 200),
        .headerView(assetName: "vulcano", height: 200),
    ]
}

// MARK: - Section

nonisolated enum Section: Hashable, Sendable {
    case colors
    case views

    var title: String {
        switch self {
        case .colors: "Colors"
        case .views: "Views"
        }
    }
}

// MARK: - StyleItem

nonisolated enum StyleItem: Hashable, Sendable {
    case color(name: String, red: CGFloat, green: CGFloat, blue: CGFloat)
    case headerView(assetName: String, height: CGFloat = 240, minHeight: CGFloat? = nil)

    var name: String {
        switch self {
        case let .color(name, _, _, _): name
        case let .headerView(assetName, _, _): assetName.capitalized
        }
    }

    var image: UIImage? {
        switch self {
        case let .color(_, red, green, blue):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return Self.colorImage(for: color)
        case let .headerView(assetName, _, _):
            return UIImage(named: assetName)
        }
    }

    var style: HeroHeader.Style {
        switch self {
        case let .color(_, red, green, blue):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return .color(backgroundColor: color, foregroundColor: .white)
        case let .headerView(assetName, height, minHeight):
            let imageView = UIImageView(image: UIImage(named: assetName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: height,
                minHeight: minHeight
            )
            return .headerView(view: imageView, configuration: configuration)
        }
    }

    private static func colorImage(
        for color: UIColor,
        size: CGSize = CGSize(width: 28, height: 28)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
