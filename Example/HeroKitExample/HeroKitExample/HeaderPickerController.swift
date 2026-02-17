import Combine
import HeroKit
import UIKit

protocol HeaderPickerControllerDelegate: AnyObject {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithTitle title: String,
        style: HeroHeader.Style
    )
    func headerPicker(_ controller: HeaderPickerController, showSettings: Void)
}

class HeaderPickerController: UIViewController, UICollectionViewDelegate, HeroHeaderDelegate {

    weak var delegate: HeaderPickerControllerDelegate?

    private let viewModel: ViewModel
    private var cancellables = Set<AnyCancellable>()

    init(title: String, navbarStyle: HeroHeader.Style?) {
        viewModel = ViewModel(style: navbarStyle)
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

        let imageCellRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell,
            HeroHeader.Style
        > { cell, _, style in
            var content = cell.defaultContentConfiguration()
            content.text = style.displayName
            content.secondaryText = style.cellSubtitle
            content.image = UIImage(systemName: "photo")
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            content.imageProperties.cornerRadius = 6
            content.imageProperties.tintColor = .secondaryLabel
            cell.contentConfiguration = content

            if case let .image(url, _, _, _, _, _) = style {
                Task {
                    guard let (data, _) = try? await URLSession.shared.data(from: url),
                          let image = UIImage(data: data)
                    else { return }
                    var updated = cell.defaultContentConfiguration()
                    updated.text = style.displayName
                    updated.secondaryText = style.cellSubtitle
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
            case let .imageStyle(index):
                let style = ViewModel.imageStyles[index]
                return collectionView.dequeueConfiguredReusableCell(
                    using: imageCellRegistration,
                    for: indexPath,
                    item: style
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
        if let initialStyle = viewModel.styleSubject.value {
            headerDelegate = self
            try? setHeader(initialStyle)
        }
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Subscribe to updates only (skip initial value)
        viewModel.styleSubject
            .dropFirst()
            .compactMap(\.self)
            .sink { [weak self] style in
                guard let self else { return }
                try? setHeader(style)
            }
            .store(in: &cancellables)
    }

    private func setupNavigationBar() {
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            primaryAction: UIAction { [weak self] _ in
                guard let self else { return }
                delegate?.headerPicker(self, showSettings: ())
            }
        )

        guard viewModel.isHeaderViewStyle else {
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

        let style: HeroHeader.Style = switch item {
        case let .colorStyle(index):
            ViewModel.colorStyles[index]
        case let .headerViewStyle(index):
            ViewModel.headerViewStyles[index]
        case let .imageStyle(index):
            ViewModel.imageStyles[index]
        }

        delegate?.headerPicker(
            self,
            didPickCellWithTitle: style.displayName,
            style: style
        )
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([Section.colors, Section.views, Section.images])
        snapshot.appendItems(
            ViewModel.colorStyles.indices.map { Item.colorStyle($0) },
            toSection: Section.colors
        )
        snapshot.appendItems(
            ViewModel.headerViewStyles.indices.map { Item.headerViewStyle($0) },
            toSection: Section.views
        )
        snapshot.appendItems(
            ViewModel.imageStyles.indices.map { Item.imageStyle($0) },
            toSection: Section.images
        )
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - Section

nonisolated enum Section: Hashable, Sendable {
    case colors
    case views
    case images

    var title: String {
        switch self {
        case .colors: "Colors"
        case .views: "Views"
        case .images: "Image URLs"
        }
    }
}

// MARK: - Item

nonisolated enum Item: Hashable, Sendable {
    case colorStyle(Int)
    case headerViewStyle(Int)
    case imageStyle(Int)
}

// MARK: - ContentMode helpers

extension UIView.ContentMode {
    var displayName: String {
        switch self {
        case .scaleAspectFill: "Aspect Fill"
        case .scaleAspectFit: "Aspect Fit"
        case .scaleToFill: "Scale to Fill"
        default: "Other"
        }
    }
}

// MARK: - LargeTitleDisplayMode helpers

extension HeroHeader.LargeTitleDisplayMode {
    var displayName: String {
        switch self {
        case .none: "None"
        case .belowHeader: "Below Header"
        case .inline: "Inline"
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
