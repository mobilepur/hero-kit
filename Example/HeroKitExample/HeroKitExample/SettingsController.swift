import UIKit

protocol SettingsControllerDelegate: AnyObject {
    func settingsController(
        _ controller: SettingsController,
        didChangeLightModeOnly value: Bool
    )
}

class SettingsController: UIViewController {

    weak var delegate: SettingsControllerDelegate?

    private var settings: AppComposer.AppSettings

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
            let toggleRegistration = UICollectionView.CellRegistration<
                UICollectionViewListCell,
                SettingsItem
            > { [weak self] cell, _, item in
                guard let self else { return }
                var content = cell.defaultContentConfiguration()
                content.text = item.title
                cell.contentConfiguration = content

                let toggle = UISwitch()
                switch item {
                case .lightModeOnly:
                    toggle.isOn = settings.lightModeOnly
                }
                toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

                cell.accessories = [.customView(configuration: .init(
                    customView: toggle,
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
                collectionView.dequeueConfiguredReusableCell(
                    using: toggleRegistration,
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
        snapshot.appendSections([SettingsSection.opaque])
        snapshot.appendItems([SettingsItem.lightModeOnly], toSection: SettingsSection.opaque)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        settings.lightModeOnly = sender.isOn
        delegate?.settingsController(self, didChangeLightModeOnly: sender.isOn)
    }
}

// MARK: - Section & Item

nonisolated enum SettingsSection: Hashable, Sendable, CaseIterable {
    case opaque

    var title: String {
        switch self {
        case .opaque: "Opaque"
        }
    }
}

nonisolated enum SettingsItem: Hashable, Sendable {
    case lightModeOnly

    var title: String {
        switch self {
        case .lightModeOnly: "Light Mode Only"
        }
    }
}
