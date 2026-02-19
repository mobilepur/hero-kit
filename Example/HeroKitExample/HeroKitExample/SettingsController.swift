import HeroKit
import UIKit

protocol SettingsControllerDelegate: AnyObject {
    func settingsControllerDidUpdate(_ controller: SettingsController)
}

class SettingsController: UIViewController {

    weak var delegate: SettingsControllerDelegate?

    private(set) var settings: AppComposer.AppSettings

    init(settings: AppComposer.AppSettings) {
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
        title = "Settings"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Collection View

    private lazy var collectionView: UICollectionView = {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<SettingsSection, SettingsItem> =
        {
            // Toggle cell registration
            let toggleRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let toggle = UISwitch()
                toggle.tag = item.tag
                switch item {
                case .lightModeOnly:
                    toggle.isOn = settings.lightModeOnly
                case .stretch:
                    toggle.isOn = settings.stretch
                case .largeTitle:
                    toggle.isOn = settings.largeTitle
                case .lineWrap:
                    toggle.isOn = settings.lineWrap
                case .inline:
                    toggle.isOn = settings.inline
                case .titleLength, .smallTitleDisplayMode, .dimming, .accessoryMode,
                     .imageContentMode, .imageBackgroundColor:
                    return
                }
                toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

                cell.accessories = [.customView(configuration: .init(
                    customView: toggle,
                    placement: .trailing()
                ))]
            }

            // Small title display mode menu registration
            let smallTitleMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
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
                        state: self?.settings.smallTitleDisplayMode == mode ? .on : .off
                    ) { [weak self] _ in
                        guard let self else { return }
                        settings.smallTitleDisplayMode = mode
                        delegate?.settingsControllerDidUpdate(self)
                        reconfigureItem(.smallTitleDisplayMode)
                    }
                }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.smallTitleDisplayMode.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            // Title length menu registration
            let titleLengthMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let button = UIButton(type: .system)
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true

                let actions = AppComposer.TitleLength.allCases.map { [weak self] length in
                    UIAction(
                        title: length.displayName,
                        state: self?.settings.titleLength == length ? .on : .off
                    ) { [weak self] _ in
                        guard let self else { return }
                        settings.titleLength = length
                        delegate?.settingsControllerDidUpdate(self)
                        reconfigureItem(.titleLength)
                    }
                }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.titleLength.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            // Dimming menu registration
            let dimmingMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
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
                            state: self?.settings.dimming == mode ? .on : .off
                        ) { [weak self] _ in
                            guard let self else { return }
                            settings.dimming = mode
                            delegate?.settingsControllerDidUpdate(self)
                            reconfigureItem(.dimming)
                        }
                    }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.dimming.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            // Accessory mode menu registration
            let accessoryMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let button = UIButton(type: .system)
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true

                let actions = AppComposer.AccessoryMode.allCases.map { [weak self] mode in
                    UIAction(
                        title: mode.displayName,
                        state: self?.settings.accessoryMode == mode ? .on : .off
                    ) { [weak self] _ in
                        guard let self else { return }
                        settings.accessoryMode = mode
                        delegate?.settingsControllerDidUpdate(self)
                        reconfigureItem(.accessoryMode)
                    }
                }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.accessoryMode.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            // Image content mode menu registration
            let contentModeMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let button = UIButton(type: .system)
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true

                let actions = AppComposer.ImageContentMode.allCases.map { [weak self] mode in
                    UIAction(
                        title: mode.displayName,
                        state: self?.settings.imageContentMode == mode ? .on : .off
                    ) { [weak self] _ in
                        guard let self else { return }
                        settings.imageContentMode = mode
                        delegate?.settingsControllerDidUpdate(self)
                        reconfigureItem(.imageContentMode)
                    }
                }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.imageContentMode.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            // Image background color menu registration
            let bgColorMenuRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let button = UIButton(type: .system)
                button.showsMenuAsPrimaryAction = true
                button.changesSelectionAsPrimaryAction = true

                let actions = AppComposer.ImageBackgroundColor.allCases.map { [weak self] bgColor in
                    UIAction(
                        title: bgColor.displayName,
                        state: self?.settings.imageBackgroundColor == bgColor ? .on : .off
                    ) { [weak self] _ in
                        guard let self else { return }
                        settings.imageBackgroundColor = bgColor
                        delegate?.settingsControllerDidUpdate(self)
                        reconfigureItem(.imageBackgroundColor)
                    }
                }

                button.menu = UIMenu(children: actions)
                button.setTitle(settings.imageBackgroundColor.displayName, for: .normal)

                cell.accessories = [.customView(configuration: .init(
                    customView: button,
                    placement: .trailing()
                ))]
            }

            let headerRegistration = UICollectionView
                .SupplementaryRegistration<UICollectionViewListCell>(
                    elementKind: UICollectionView.elementKindSectionHeader
                ) { headerView, _, indexPath in
                    var content = UIListContentConfiguration.prominentInsetGroupedHeader()
                    content.text = SettingsSection.allCases[indexPath.section].title
                    headerView.contentConfiguration = content
                }

            let dataSource = UICollectionViewDiffableDataSource<SettingsSection, SettingsItem>(
                collectionView: collectionView
            ) { collectionView, indexPath, item in
                switch item {
                case .smallTitleDisplayMode:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: smallTitleMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                case .dimming:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: dimmingMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                case .titleLength:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: titleLengthMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                case .accessoryMode:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: accessoryMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                case .imageContentMode:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: contentModeMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                case .imageBackgroundColor:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: bgColorMenuRegistration,
                        for: indexPath,
                        item: item
                    )
                default:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: toggleRegistration,
                        for: indexPath,
                        item: item
                    )
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        applySnapshot()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
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
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()
        snapshot.appendSections([.global, .opaque, .headerView, .image])
        snapshot.appendItems([.titleLength], toSection: .global)
        snapshot.appendItems([.lightModeOnly], toSection: .opaque)
        snapshot.appendItems(
            [
                .stretch,
                .largeTitle,
                .lineWrap,
                .smallTitleDisplayMode,
                .inline,
                .dimming,
                .accessoryMode,
            ],
            toSection: .headerView
        )
        snapshot.appendItems(
            [.imageContentMode, .imageBackgroundColor],
            toSection: .image
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func reconfigureItem(_ item: SettingsItem) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([item])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        guard let item = SettingsItem(tag: sender.tag) else { return }
        switch item {
        case .lightModeOnly:
            settings.lightModeOnly = sender.isOn
        case .stretch:
            settings.stretch = sender.isOn
        case .largeTitle:
            settings.largeTitle = sender.isOn
        case .lineWrap:
            settings.lineWrap = sender.isOn
        case .inline:
            settings.inline = sender.isOn
        case .titleLength, .smallTitleDisplayMode, .dimming, .accessoryMode,
             .imageContentMode, .imageBackgroundColor:
            break
        }
        delegate?.settingsControllerDidUpdate(self)
    }
}

// MARK: - Section & Item

nonisolated enum SettingsSection: Hashable, Sendable, CaseIterable {
    case global
    case opaque
    case headerView
    case image

    var title: String {
        switch self {
        case .global: "Global"
        case .opaque: "Opaque"
        case .headerView: "Header"
        case .image: "Image"
        }
    }
}

nonisolated enum SettingsItem: Hashable, Sendable {
    case titleLength
    case lightModeOnly
    case stretch
    case largeTitle
    case lineWrap
    case smallTitleDisplayMode
    case inline
    case dimming
    case accessoryMode
    case imageContentMode
    case imageBackgroundColor

    var title: String {
        switch self {
        case .titleLength: "Title"
        case .lightModeOnly: "Light Mode Only"
        case .stretch: "Stretch"
        case .largeTitle: "Large Title"
        case .lineWrap: "Line Wrap"
        case .smallTitleDisplayMode: "Small Title"
        case .inline: "Inline"
        case .dimming: "Dimming"
        case .accessoryMode: "Accessory"
        case .imageContentMode: "Content Mode"
        case .imageBackgroundColor: "Background Color"
        }
    }

    var tag: Int {
        switch self {
        case .titleLength: 0
        case .lightModeOnly: 1
        case .stretch: 2
        case .largeTitle: 3
        case .lineWrap: 4
        case .smallTitleDisplayMode: 5
        case .inline: 6
        case .dimming: 7
        case .accessoryMode: 8
        case .imageContentMode: 9
        case .imageBackgroundColor: 10
        }
    }

    init?(tag: Int) {
        switch tag {
        case 0: self = .titleLength
        case 1: self = .lightModeOnly
        case 2: self = .stretch
        case 3: self = .largeTitle
        case 4: self = .lineWrap
        case 5: self = .smallTitleDisplayMode
        case 6: self = .inline
        case 7: self = .dimming
        case 8: self = .accessoryMode
        case 9: self = .imageContentMode
        case 10: self = .imageBackgroundColor
        default: return nil
        }
    }
}
