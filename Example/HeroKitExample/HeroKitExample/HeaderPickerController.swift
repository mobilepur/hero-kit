import Combine
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

    var delegate: HeaderPickerControllerDelegate?

    private let viewModel: ViewModel
    private var cancellables = Set<AnyCancellable>()

    init(title: String, navbarStyle: HeroHeader.Style?, assetName: String? = nil) {
        viewModel = ViewModel(style: navbarStyle, assetName: assetName)
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
            HeroHeader.Style
        > { cell, _, style in
            var content = cell.defaultContentConfiguration()
            content.text = style.displayName
            content.secondaryText = style.cellSubtitle
            content.image = style.cellImage
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
                toggle.isOn = viewModel.stretchEnabled
            case .largeTitle:
                toggle.isOn = viewModel.largeTitleEnabled
            case .lineWrap:
                toggle.isOn = viewModel.lineWrapEnabled
            case .lightModeOnly:
                toggle.isOn = viewModel.lightModeOnlyEnabled
            case .smallTitleDisplayMode, .dimming, .titleChange:
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

            let actions = HeroHeader.SmallTitleDisplayMode.allCases.map { [weak self] mode in
                UIAction(
                    title: mode.displayName,
                    state: self?.viewModel.smallTitleDisplayMode == mode ? .on : .off
                ) { [weak self] _ in
                    self?.viewModel.smallTitleDisplayMode = mode
                }
            }

            button.menu = UIMenu(children: actions)
            button.setTitle(viewModel.smallTitleDisplayMode.displayName, for: .normal)

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

            let actions = HeroHeader.InlineTitleConfiguration.Dimming.allCases
                .map { [weak self] mode in
                    UIAction(
                        title: mode.displayName,
                        state: self?.viewModel.dimmingMode == mode ? .on : .off
                    ) { [weak self] _ in
                        self?.viewModel.dimmingMode = mode
                    }
                }

            button.menu = UIMenu(children: actions)
            button.setTitle(viewModel.dimmingMode.displayName, for: .normal)

            cell.accessories = [.customView(configuration: .init(
                customView: button,
                placement: .trailing()
            ))]
        }

        // Title menu cell registration
        let titleMenuCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            ConfigItem
        > { [weak self] cell, _, item in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content

            let button = UIButton(type: .system)
            button.showsMenuAsPrimaryAction = true

            let titles = [
                "Short",
                "A Medium Length Title",
                "This Is A Very Long Title That Spans Multiple Lines",
            ]

            let actions = titles.map { titleOption in
                UIAction(title: titleOption) { [weak self] _ in
                    self?.title = titleOption
                }
            }

            button.menu = UIMenu(children: actions)
            button.setTitle(title ?? "Select", for: .normal)

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
            case let .colorStyle(index):
                let style = ViewModel.colorStyles[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: styleCellRegistration,
                    for: indexPath,
                    item: style
                )
            case let .headerViewStyle(index):
                let style = ViewModel.headerViewStyles[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: styleCellRegistration,
                    for: indexPath,
                    item: style
                )
            case let .config(configItem):
                switch configItem {
                case .smallTitleDisplayMode:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: menuCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                case .dimming:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: dimmingMenuCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                case .titleChange:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: titleMenuCellRegistration,
                        for: indexPath,
                        item: configItem
                    )
                default:
                    return collectionView.dequeueConfiguredReusableCell(
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
        super.viewDidLoad()

        if #unavailable(iOS 26) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }

        setupCollectionView()
        setupNavigationBar()
        applySnapshot()
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.styleSubject
            .compactMap(\.self)
            .sink { [weak self] style in
                guard let self else { return }
                headerDelegate = self
                try? setHeader(style)
            }
            .store(in: &cancellables)
    }

    private func setupNavigationBar() {
        // Only show menu for headerView styles (APIs don't work for color style)
        guard viewModel.isHeaderViewStyle else { return }

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
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        let style: HeroHeader.Style
        switch item {
        case let .colorStyle(index):
            style = ViewModel.colorStyles[index]
        case let .headerViewStyle(index):
            style = ViewModel.headerViewStyles[index]
        case .config:
            return
        }

        delegate?.headerPicker(
            self,
            didPickCellWithTitle: style.displayName,
            style: style,
            assetName: style.assetName
        )
    }

    private func applySnapshot(animatingDifferences: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        // Show configuration section for headerView styles
        if viewModel.isHeaderViewStyle {
            snapshot.appendSections([Section.configuration])

            var configItems: [Item] = [
                Item.config(.stretch),
                Item.config(.largeTitle),
            ]

            // Show lineWrap and smallTitleDisplayMode only when largeTitle is enabled
            if viewModel.largeTitleEnabled {
                configItems.append(Item.config(.lineWrap))
                configItems.append(Item.config(.smallTitleDisplayMode))
            }

            // Show dimming option for inline titles
            if viewModel.inlineEnabled {
                configItems.append(Item.config(.dimming))
            }

            // Always show title change option
            configItems.append(Item.config(.titleChange))

            snapshot.appendItems(configItems, toSection: Section.configuration)
        }

        // Show configuration section for opaque styles
        if viewModel.isOpaqueStyle {
            snapshot.appendSections([Section.configuration])
            snapshot.appendItems([Item.config(.lightModeOnly)], toSection: Section.configuration)
        }

        snapshot.appendSections([Section.colors, Section.views])
        snapshot.appendItems(
            ViewModel.colorStyles.indices.map { Item.colorStyle($0) },
            toSection: Section.colors
        )
        snapshot.appendItems(
            ViewModel.headerViewStyles.indices.map { Item.headerViewStyle($0) },
            toSection: Section.views
        )
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    @objc private func configToggleChanged(_ sender: UISwitch) {
        guard let configItem = ConfigItem(tag: sender.tag) else { return }

        switch configItem {
        case .stretch:
            viewModel.stretchEnabled = sender.isOn
        case .largeTitle:
            viewModel.largeTitleEnabled = sender.isOn
            applySnapshot(animatingDifferences: true)
        case .lineWrap:
            viewModel.lineWrapEnabled = sender.isOn
        case .lightModeOnly:
            viewModel.lightModeOnlyEnabled = sender.isOn
        case .smallTitleDisplayMode, .dimming, .titleChange:
            break
        }
    }

    // MARK: - HeroHeaderDelegate

    func heroHeader(_: UIViewController, didShowLargeTitle _: HeroHeaderView) {
        print("didShowLargeTitle")
    }

    func heroHeader(_: UIViewController, didShowSmallTitle _: HeroHeaderView) {
        print("didShowSmallTitle")
    }

    func heroHeader(_: UIViewController, didUpdateTitle _: HeroHeaderView, title: String) {
        print("didUpdateTitle: \(title)")
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

// MARK: - Item

nonisolated enum Item: Hashable, Sendable {
    case colorStyle(Int)
    case headerViewStyle(Int)
    case config(ConfigItem)
}

// MARK: - ConfigItem

nonisolated enum ConfigItem: Hashable, Sendable {
    case stretch
    case largeTitle
    case lineWrap
    case smallTitleDisplayMode
    case dimming
    case titleChange
    case lightModeOnly

    var title: String {
        switch self {
        case .stretch: "Stretch"
        case .largeTitle: "Large Title"
        case .lineWrap: "Line Wrap"
        case .smallTitleDisplayMode: "Small Title"
        case .dimming: "Dimming"
        case .titleChange: "Title"
        case .lightModeOnly: "Light Mode Only"
        }
    }

    var tag: Int {
        switch self {
        case .stretch: 0
        case .largeTitle: 1
        case .lineWrap: 2
        case .smallTitleDisplayMode: 3
        case .dimming: 4
        case .titleChange: 5
        case .lightModeOnly: 6
        }
    }

    init?(tag: Int) {
        switch tag {
        case 0: self = .stretch
        case 1: self = .largeTitle
        case 2: self = .lineWrap
        case 3: self = .smallTitleDisplayMode
        case 4: self = .dimming
        case 5: self = .titleChange
        case 6: self = .lightModeOnly
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
