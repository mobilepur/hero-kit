import HeroKit
import UIKit

protocol HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithTitle title: String,
        style: HeroHeader.Style,
        assetName: String?
    )
}

class HeaderPickerController: UIViewController, UICollectionViewDelegate, HeroHeaderDelegate {

    let navbarStyle: HeroHeader.Style?
    var delegate: HeaderPickerControllerDelegate?

    // Configuration state for live updates
    private var currentConfiguration: HeroHeader.HeaderViewConfiguration?
    private var currentAssetName: String?
    private var stretchEnabled: Bool = true
    private var largeTitleEnabled: Bool = false
    private var lineWrapEnabled: Bool = false
    private var smallTitleDisplayMode: HeroHeader.SmallTitleDisplayMode = .system
    private var inlineEnabled: Bool = false
    private var dimmingMode: HeroHeader.InlineTitleConfiguration.Dimming = .none

    init(title: String, navbarStyle: HeroHeader.Style?, assetName: String? = nil) {
        self.navbarStyle = navbarStyle
        currentAssetName = assetName

        // Extract configuration if headerView style
        if case let .headerView(_, configuration) = navbarStyle {
            currentConfiguration = configuration
            stretchEnabled = configuration.stretches

            // Extract large title settings
            if case let .belowHeader(largeTitleConfig) = configuration.largeTitleDisplayMode {
                largeTitleEnabled = true
                lineWrapEnabled = largeTitleConfig.allowsLineWrap
                smallTitleDisplayMode = largeTitleConfig.smallTitleDisplayMode
            }
            if case let .inline(inlineConfig) = configuration.largeTitleDisplayMode {
                inlineEnabled = true
                dimmingMode = inlineConfig.dimming
            }
        }

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

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = {
        // Style cell registration
        let styleCellRegistration = UICollectionView.CellRegistration<
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

        // Toggle cell registration for configuration items
        let toggleCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            ConfigItem
        > { [weak self] cell, _, item in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content

            let toggle = UISwitch()
            toggle.tag = item.tag

            switch item {
            case .stretch:
                toggle.isOn = stretchEnabled
            case .largeTitle:
                toggle.isOn = largeTitleEnabled
            case .lineWrap:
                toggle.isOn = lineWrapEnabled
            case .smallTitleDisplayMode, .dimming:
                return // Handled by menu registration
            }

            toggle.addTarget(self, action: #selector(configToggleChanged(_:)), for: .valueChanged)
            cell.accessories = [.customView(configuration: .init(
                customView: toggle,
                placement: .trailing()
            ))]
        }

        // Menu cell registration for smallTitleDisplayMode
        let menuCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            ConfigItem
        > { [weak self] cell, _, item in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content

            let button = UIButton(type: .system)
            button.showsMenuAsPrimaryAction = true
            button.changesSelectionAsPrimaryAction = true

            let actions = HeroHeader.SmallTitleDisplayMode.allCases.map { mode in
                UIAction(
                    title: mode.displayName,
                    state: self.smallTitleDisplayMode == mode ? .on : .off
                ) { [weak self] _ in
                    self?.smallTitleDisplayMode = mode
                    self?.updateHeaderWithCurrentConfiguration()
                }
            }

            button.menu = UIMenu(children: actions)
            button.setTitle(smallTitleDisplayMode.displayName, for: .normal)

            cell.accessories = [.customView(configuration: .init(
                customView: button,
                placement: .trailing()
            ))]
        }

        // Dimming menu cell registration
        let dimmingMenuCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            ConfigItem
        > { [weak self] cell, _, item in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content

            let button = UIButton(type: .system)
            button.showsMenuAsPrimaryAction = true
            button.changesSelectionAsPrimaryAction = true

            let actions = HeroHeader.InlineTitleConfiguration.Dimming.allCases.map { mode in
                UIAction(
                    title: mode.displayName,
                    state: self.dimmingMode == mode ? .on : .off
                ) { [weak self] _ in
                    self?.dimmingMode = mode
                    self?.updateHeaderWithCurrentConfiguration()
                }
            }

            button.menu = UIMenu(children: actions)
            button.setTitle(dimmingMode.displayName, for: .normal)

            cell.accessories = [.customView(configuration: .init(
                customView: button,
                placement: .trailing()
            ))]
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

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case let .style(styleItem):
                collectionView.dequeueConfiguredReusableCell(
                    using: styleCellRegistration,
                    for: indexPath,
                    item: styleItem
                )
            case let .config(configItem):
                switch configItem {
                case .smallTitleDisplayMode:
                    collectionView.dequeueConfiguredReusableCell(
                        using: menuCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                case .dimming:
                    collectionView.dequeueConfiguredReusableCell(
                        using: dimmingMenuCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                default:
                    collectionView.dequeueConfiguredReusableCell(
                        using: toggleCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                }
            }
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
        setupNavigationBar()
        applySnapshot()
        if let navbarStyle {
            headerDelegate = self
            try? setHeader(navbarStyle)
        }
    }

    private func setupNavigationBar() {
        // Only show menu for headerView styles (APIs don't work for color style)
        guard currentConfiguration != nil else { return }

        let menu = UIMenu(children: [
            UIAction(
                title: "Expand Header",
                image: UIImage(systemName: "arrow.up.left.and.arrow.down.right")
            ) { [weak self] _ in
                self?.expandHeader()
            },
            UIAction(
                title: "Collapse Content",
                image: UIImage(systemName: "arrow.down.right.and.arrow.up.left")
            ) { [weak self] _ in
                self?.collapseHeaderContent()
            },
            UIAction(title: "Collapse Header",
                     image: UIImage(systemName: "chevron.up"))
            { [weak self] _ in
                self?.collapseHeader()
            },
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: menu
        )
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
        guard let item = dataSource.itemIdentifier(for: indexPath),
              case let .style(styleItem) = item
        else { return }
        delegate?.headerPicker(
            self,
            didPickCellWithTitle: styleItem.name,
            style: styleItem.style,
            assetName: styleItem.assetName
        )
    }

    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        // Show configuration section only for headerView styles
        if currentConfiguration != nil {
            snapshot.appendSections([Section.configuration])

            var configItems: [Item] = [
                Item.config(.stretch),
                Item.config(.largeTitle),
            ]

            // Show lineWrap and smallTitleDisplayMode only when largeTitle is enabled
            if largeTitleEnabled {
                configItems.append(Item.config(.lineWrap))
                configItems.append(Item.config(.smallTitleDisplayMode))
            }

            // Show dimming option for inline titles
            if inlineEnabled {
                configItems.append(Item.config(.dimming))
            }

            snapshot.appendItems(configItems, toSection: Section.configuration)
        }

        snapshot.appendSections([Section.colors, Section.views])
        snapshot.appendItems(colorItems.map { Item.style($0) }, toSection: Section.colors)
        snapshot.appendItems(viewItems.map { Item.style($0) }, toSection: Section.views)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    @objc private func configToggleChanged(_ sender: UISwitch) {
        guard let configItem = ConfigItem(tag: sender.tag) else { return }

        switch configItem {
        case .stretch:
            stretchEnabled = sender.isOn
        case .largeTitle:
            largeTitleEnabled = sender.isOn
            applySnapshot(animatingDifferences: true)
        case .lineWrap:
            lineWrapEnabled = sender.isOn
        case .smallTitleDisplayMode, .dimming:
            break
        }

        updateHeaderWithCurrentConfiguration()
    }

    private func updateHeaderWithCurrentConfiguration() {
        guard let config = currentConfiguration,
              let assetName = currentAssetName
        else { return }

        let imageView = UIImageView(image: UIImage(named: assetName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        let largeTitleDisplayMode: HeroHeader.LargeTitleDisplayMode = if inlineEnabled {
            .inline(.init(dimming: dimmingMode))
        } else if largeTitleEnabled {
            .belowHeader(.init(
                allowsLineWrap: lineWrapEnabled,
                smallTitleDisplayMode: smallTitleDisplayMode
            ))
        } else {
            .none
        }

        let newConfiguration = HeroHeader.HeaderViewConfiguration(
            height: config.height,
            minHeight: config.minHeight,
            stretches: stretchEnabled,
            largeTitleDisplayMode: largeTitleDisplayMode
        )

        try? setHeader(.headerView(view: imageView, configuration: newConfiguration))
    }

    // MARK: - Data

    private let colorItems: [StyleItem] = [
        .color(name: "Red", red: 1.0, green: 0.23, blue: 0.19, prefersLargeTitles: true),
        .color(name: "Orange", red: 1.0, green: 0.58, blue: 0.0),
        .color(name: "Green", red: 0.2, green: 0.78, blue: 0.35, prefersLargeTitles: true),
        .color(name: "Teal", red: 0.19, green: 0.69, blue: 0.78),
        .color(name: "Blue", red: 0.0, green: 0.48, blue: 1.0, prefersLargeTitles: true),
        .color(name: "Indigo", red: 0.35, green: 0.34, blue: 0.84),
        .color(name: "Purple", red: 0.69, green: 0.32, blue: 0.87, prefersLargeTitles: true),
        .color(name: "Pink", red: 1.0, green: 0.18, blue: 0.33),
    ]

    private let viewItems: [StyleItem] = [
        // No large title
        .headerView(title: "Bikes", assetName: "bikes", height: 300),

        // Single line large title
        .headerView(
            title: "Explore",
            assetName: "temple",
            height: 300,
            largeTitleDisplayMode: .belowHeader()
        ),

        // Inline large title
        .headerView(
            title: "Bikes & Beyond",
            assetName: "bikes",
            height: 300,
            largeTitleDisplayMode: .inline()
        ),

        // Two line large title
        .headerView(
            title: "Ancient Temples of Bali",
            assetName: "vulcano",
            height: 300,
            largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
        ),
    ]

    // MARK: - HeroHeaderDelegate

    func heroHeader(_: UIViewController, didShowLargeTitle _: HeroHeaderView) {
        print("didShowLargeTitle")
    }

    func heroHeader(_: UIViewController, didShowSmallTitle _: HeroHeaderView) {
        print("didShowSmallTitle")
    }

    /*
     func heroHeader(_: UIViewController, didSetup headerView: HeroHeaderView) {
         print("didSetup: \(headerView)")
     }

     func heroHeader(_: UIViewController, didScroll _: HeroHeaderView, offset _: CGFloat) {
         // print("didScroll: offset=\(offset)")
     }

     func heroHeader(_: UIViewController, didCollapse _: HeroHeaderView) {
         print("didCollapse")
     }

     func heroHeader(_: UIViewController, didBecameVisible _: HeroHeaderView) {
         print("didBecameVisible")
     }

     func heroHeader(_: UIViewController, didExpandFully _: HeroHeaderView) {
         print("didExpandFully")
     }

     func heroHeader(_: UIViewController, didStretch _: HeroHeaderView) {
         print("didStretch")
     }

     func heroHeader(_: UIViewController, didUnstretch _: HeroHeaderView) {
         print("didUnstretch")
     }

     func heroHeader(_: UIViewController, didCollapseHeaderContent _: HeroHeaderView) {
         print("didCollapseHeaderContent")
     }

     func heroHeader(_: UIViewController, headerContentDidBecameVisible _: HeroHeaderView) {
         print("headerContentDidBecameVisible")
     }
     */
}

// MARK: - Section

nonisolated enum Section: Hashable, Sendable {
    case configuration
    case colors
    case views

    var title: String {
        switch self {
        case .configuration: "Configuration"
        case .colors: "Colors"
        case .views: "Views"
        }
    }
}

// MARK: - StyleItem

nonisolated enum StyleItem: Hashable, Sendable {
    case color(
        name: String,
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        prefersLargeTitles: Bool = false
    )
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
        case let .color(name, _, _, _, _): name
        case let .headerView(title, _, _, _, _, _): title
        }
    }

    var assetName: String? {
        switch self {
        case .color: nil
        case let .headerView(_, assetName, _, _, _, _): assetName
        }
    }

    var image: UIImage? {
        switch self {
        case let .color(_, red, green, blue, _):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return Self.colorImage(for: color)
        case let .headerView(_, assetName, _, _, _, _):
            return UIImage(named: assetName)
        }
    }

    var subtitle: String? {
        switch self {
        case let .color(_, _, _, _, prefersLargeTitles):
            return prefersLargeTitles ? "Large Title" : nil
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
        case let .color(_, red, green, blue, prefersLargeTitles):
            let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            return .opaque(
                backgroundColor: color,
                foregroundColor: .white,
                prefersLargeTitles: prefersLargeTitles
            )
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

// MARK: - Item

nonisolated enum Item: Hashable, Sendable {
    case style(StyleItem)
    case config(ConfigItem)
}

// MARK: - ConfigItem

nonisolated enum ConfigItem: Hashable, Sendable {
    case stretch
    case largeTitle
    case lineWrap
    case smallTitleDisplayMode
    case dimming

    var title: String {
        switch self {
        case .stretch: "Stretch"
        case .largeTitle: "Large Title"
        case .lineWrap: "Line Wrap"
        case .smallTitleDisplayMode: "Small Title"
        case .dimming: "Dimming"
        }
    }

    var tag: Int {
        switch self {
        case .stretch: 0
        case .largeTitle: 1
        case .lineWrap: 2
        case .smallTitleDisplayMode: 3
        case .dimming: 4
        }
    }

    init?(tag: Int) {
        switch tag {
        case 0: self = .stretch
        case 1: self = .largeTitle
        case 2: self = .lineWrap
        case 3: self = .smallTitleDisplayMode
        case 4: self = .dimming
        default: return nil
        }
    }
}

// MARK: - SmallTitleDisplayMode helpers

extension HeroHeader.SmallTitleDisplayMode {
    static var allCases: [HeroHeader.SmallTitleDisplayMode] {
        [.never, .system, .always]
    }

    var displayName: String {
        switch self {
        case .never: "Never"
        case .system: "System"
        case .always: "Always"
        }
    }
}

// MARK: - Dimming helpers

extension HeroHeader.InlineTitleConfiguration.Dimming {
    static var allCases: [HeroHeader.InlineTitleConfiguration.Dimming] {
        [.none, .complete, .gradient]
    }

    var displayName: String {
        switch self {
        case .none: "None"
        case .complete: "Complete"
        case .gradient: "Gradient"
        }
    }
}
