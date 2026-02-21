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
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.sectionIdentifier(for: sectionIndex) else {
                return nil
            }

            switch section {
            case .transitions:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(220)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(220)
                )
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8, leading: 20, bottom: 20, trailing: 20
                )

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section

            default:
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.headerMode = .supplementary
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
            }
        }

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

        let transitionCellRegistration = UICollectionView.CellRegistration<
            TransitionImageCell,
            HeaderContent
        > { cell, _, content in
            cell.configure(with: content)
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
            case let .transitionItem(index):
                let content = HeaderContent.transitionItems[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: transitionCellRegistration,
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
        case let .transitionItem(index):
            HeaderContent.transitionItems[index]
        }

        delegate?.headerPicker(self, didSelect: selectedContent)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.colors, .localImages, .remoteImages, .transitions])
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
        snapshot.appendItems(
            HeaderContent.transitionItems.indices.map { Item.transitionItem($0) },
            toSection: .transitions
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Section

nonisolated enum Section: Hashable, Sendable {
    case colors
    case localImages
    case remoteImages
    case transitions

    var title: String {
        switch self {
        case .colors: "Colors"
        case .localImages: "Views"
        case .remoteImages: "Image URLs"
        case .transitions: "Transitions"
        }
    }
}

// MARK: - Item

nonisolated enum Item: Hashable, Sendable {
    case colorItem(Int)
    case localImageItem(Int)
    case remoteImageItem(Int)
    case transitionItem(Int)
}

// MARK: - TransitionImageCell

final class TransitionImageCell: UICollectionViewCell {

    let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.6
        label.layer.shadowRadius = 3
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(heroImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -12),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: heroImageView.trailingAnchor, constant: -12
            ),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with content: HeaderContent) {
        titleLabel.text = content.displayName
        if case let .localImage(_, _, assetName, _) = content {
            heroImageView.image = UIImage(named: assetName)
        }
    }
}
