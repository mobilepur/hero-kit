import HeroKit
import UIKit

protocol HeaderPickerControllerDelegate: AnyObject {
    func headerPicker(_ controller: HeaderPickerController, didSelect content: HeaderContent)
    func headerPicker(_ controller: HeaderPickerController, showSettings: Void)
}

class HeaderPickerController: UIViewController, UICollectionViewDelegate, HeroHeaderDelegate {

    weak var delegate: HeaderPickerControllerDelegate?

    /// The content descriptor used by AppComposer to rebuild the style when settings change.
    var content: HeaderContent?

    private let initialStyle: HeroHeader.Style?

    init(title: String, navbarStyle: HeroHeader.Style?) {
        initialStyle = navbarStyle
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
        let contentCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            HeaderContent
        > { cell, _, content in
            var config = cell.defaultContentConfiguration()
            config.text = content.displayName
            config.secondaryText = content.cellSubtitle
            config.image = content.cellImage
            config.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            config.imageProperties.cornerRadius = 6
            cell.contentConfiguration = config
        }

        let remoteCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            HeaderContent
        > { cell, _, content in
            var config = cell.defaultContentConfiguration()
            config.text = content.displayName
            config.secondaryText = content.cellSubtitle
            config.image = UIImage(systemName: "photo")
            config.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            config.imageProperties.cornerRadius = 6
            config.imageProperties.tintColor = .secondaryLabel
            cell.contentConfiguration = config

            if case let .remoteImage(_, _, url, _) = content {
                Task {
                    guard let (data, _) = try? await URLSession.shared.data(from: url),
                          let image = UIImage(data: data)
                    else { return }
                    var updated = cell.defaultContentConfiguration()
                    updated.text = content.displayName
                    updated.secondaryText = content.cellSubtitle
                    updated.image = image
                    updated.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                    updated.imageProperties.cornerRadius = 6
                    cell.contentConfiguration = updated
                }
            }
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
            case let .colorItem(index):
                let content = HeaderContent.colorItems[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: contentCellRegistration,
                    for: indexPath,
                    item: content
                )
            case let .localImageItem(index):
                let content = HeaderContent.localImageItems[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: contentCellRegistration,
                    for: indexPath,
                    item: content
                )
            case let .remoteImageItem(index):
                let content = HeaderContent.remoteImageItems[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: remoteCellRegistration,
                    for: indexPath,
                    item: content
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

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupNavigationBar()
        applySnapshot()
        if let initialStyle {
            headerDelegate = self
            setHeader(initialStyle)
        }
    }

    private func setupNavigationBar() {
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            primaryAction: UIAction { [weak self] _ in
                guard let self else { return }
                delegate?.headerPicker(self, showSettings: ())
            }
        )

        guard content?.isVisualHeader == true else {
            navigationItem.rightBarButtonItem = settingsButton
            return
        }

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

        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: menu
        )

        navigationItem.rightBarButtonItems = [settingsButton, menuButton]
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

        let selectedContent = switch item {
        case let .colorItem(index):
            HeaderContent.colorItems[index]
        case let .localImageItem(index):
            HeaderContent.localImageItems[index]
        case let .remoteImageItem(index):
            HeaderContent.remoteImageItems[index]
        }

        delegate?.headerPicker(self, didSelect: selectedContent)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.colors, .localImages, .remoteImages])
        snapshot.appendItems(
            HeaderContent.colorItems.indices.map { Item.colorItem($0) },
            toSection: .colors
        )
        snapshot.appendItems(
            HeaderContent.localImageItems.indices.map { Item.localImageItem($0) },
            toSection: .localImages
        )
        snapshot.appendItems(
            HeaderContent.remoteImageItems.indices.map { Item.remoteImageItem($0) },
            toSection: .remoteImages
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Section

nonisolated enum Section: Hashable, Sendable {
    case colors
    case localImages
    case remoteImages

    var title: String {
        switch self {
        case .colors: "Colors"
        case .localImages: "Views"
        case .remoteImages: "Image URLs"
        }
    }
}

// MARK: - Item

nonisolated enum Item: Hashable, Sendable {
    case colorItem(Int)
    case localImageItem(Int)
    case remoteImageItem(Int)
}
