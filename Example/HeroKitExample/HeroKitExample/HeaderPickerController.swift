import HeroKit
import UIKit

protocol HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithTitle title: String,
        style: HeroHeader.Style
    )
}

class HeaderPickerController: UIViewController, UICollectionViewDelegate {

    let navbarStyle: HeroHeader.Style
    var delegate: HeaderPickerControllerDelegate?

    init(title: String, navbarStyle: HeroHeader.Style) {
        self.navbarStyle = navbarStyle
        super.init(nibName: nil, bundle: nil)
        self.title = title
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
            content.secondaryText = item.subtitle
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
                var content = UIListContentConfiguration.prominentInsetGroupedHeader()
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
        delegate?.headerPicker(self, didPickCellWithTitle: item.name, style: item.style)
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
        .color(name: "Green", red: 0.2, green: 0.78, blue: 0.35),
        .color(name: "Teal", red: 0.19, green: 0.69, blue: 0.78),
        .color(name: "Blue", red: 0.0, green: 0.48, blue: 1.0),
        .color(name: "Indigo", red: 0.35, green: 0.34, blue: 0.84),
        .color(name: "Purple", red: 0.69, green: 0.32, blue: 0.87),
        .color(name: "Pink", red: 1.0, green: 0.18, blue: 0.33),
    ]

    private let viewItems: [StyleItem] = [
        // Height 300, no options
        .headerView(title: "Bikes", assetName: "bikes", height: 300),
        // Height 500, no options
        .headerView(title: "Rice Fields", assetName: "ricefields", height: 500),

        // Height 300, stretches
        .headerView(title: "Temple", assetName: "temple", height: 300, stretches: true),
        // Height 300, no stretch
        .headerView(title: "Vulcano", assetName: "vulcano", height: 300, stretches: false),

        // Height 500, minHeight
        .headerView(title: "Bikes", assetName: "bikes", height: 500, minHeight: 100),
        // Height 300, minHeight, stretches
        .headerView(
            title: "Rice Fields",
            assetName: "ricefields",
            height: 300,
            minHeight: 80,
            stretches: true
        ),

        // Large title
        .headerView(
            title: "Explore",
            assetName: "temple",
            height: 300,
            largeTitleDisplayMode: .belowHeader()
        ),
        // Large title, stretches
        .headerView(
            title: "Discover",
            assetName: "vulcano",
            height: 300,
            stretches: true,
            largeTitleDisplayMode: .belowHeader()
        ),
        // Large title, minHeight
        .headerView(
            title: "Adventure",
            assetName: "bikes",
            height: 500,
            minHeight: 100,
            largeTitleDisplayMode: .belowHeader()
        ),

        // Large title with wrap
        .headerView(
            title: "Ancient Temples of Bali",
            assetName: "temple",
            height: 300,
            largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
        ),
        // Large title with wrap, stretches
        .headerView(
            title: "Beautiful Rice Terraces",
            assetName: "ricefields",
            height: 300,
            stretches: true,
            largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
        ),
        // Large title with wrap, minHeight, stretches
        .headerView(
            title: "Volcanic Wonders of Indonesia",
            assetName: "vulcano",
            height: 500,
            minHeight: 120,
            stretches: true,
            largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
        ),
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
    case headerView(
        title: String,
        assetName: String,
        height: CGFloat = 240,
        minHeight: CGFloat? = nil,
        stretches: Bool = true,
        largeTitleDisplayMode: HeroHeader.LargeTitleDisplayMode = .none
    )

    var name: String {
        switch self {
        case let .color(name, _, _, _): name
        case let .headerView(title, _, _, _, _, _): title
        }
    }

    var image: UIImage? {
        switch self {
        case let .color(_, red, green, blue):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return Self.colorImage(for: color)
        case let .headerView(_, assetName, _, _, _, _):
            return UIImage(named: assetName)
        }
    }

    var subtitle: String? {
        switch self {
        case .color:
            return nil
        case let .headerView(_, _, height, minHeight, stretches, largeTitleDisplayMode):
            let config = HeroHeader.HeaderViewConfiguration(
                height: height,
                minHeight: minHeight,
                stretches: stretches,
                largeTitleDisplayMode: largeTitleDisplayMode
            )
            return config.description
        }
    }

    var style: HeroHeader.Style {
        switch self {
        case let .color(name, red, green, blue):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return .color(backgroundColor: color, foregroundColor: .white)
        case let .headerView(_, assetName, height, minHeight, stretches, largeTitleDisplayMode):
            let imageView = UIImageView(image: UIImage(named: assetName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: height,
                minHeight: minHeight,
                stretches: stretches,
                largeTitleDisplayMode: largeTitleDisplayMode
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
