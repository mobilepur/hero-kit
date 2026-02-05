import Combine
import ObjectiveC
import UIKit

// MARK: - UIViewController Extension

public extension UIViewController {

    var headerDelegate: HeroHeaderDelegate? {
        get { viewModel?.delegate ?? heroHeaderDelegate }
        set {
            heroHeaderDelegate = newValue
            viewModel?.delegate = newValue
        }
    }

    func setHeader(_ style: HeroHeader.Style, scrollView: UIScrollView? = nil) throws {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }

        // Clean up existing header if present
        cleanupExistingHeader()

        try setupHeader(style: style, scrollView: targetScrollView)
        subscribeToScrollOffset(of: targetScrollView)
    }

    /// Expands the header to fully visible state
    func expandHeader(animated: Bool = true) {
        viewModel?.expandHeader(animated: animated)
    }

    /// Collapses header content - large title still visible (if present)
    func collapseHeaderContent(animated: Bool = true) {
        viewModel?.collapseHeaderContent(animated: animated)
    }

    /// Collapses the header fully - only nav bar visible
    func collapseHeader(animated: Bool = true) {
        viewModel?.collapseHeader(animated: animated)
    }
}

// MARK: - helper

extension UIViewController {

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) throws {
        switch style {
        case let .opaque(backgroundColor, foregroundColor, prefersLargeTitles):
            try setupOpaqueHeader(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles
            )
        case let .headerView(view, configuration):
            setupHeaderView(view, configuration: configuration, scrollView: scrollView)
        }
    }

    private func setupHeaderView(
        _ contentView: UIView,
        configuration: HeroHeader.HeaderViewConfiguration,
        scrollView: UIScrollView
    ) {
        configureTransparentNavigationBar()

        let (heroHeaderView, contentConstraint) = createHeroHeaderView(
            contentView: contentView,
            configuration: configuration
        )

        let constraints = layoutHeaderView(heroHeaderView)
        let totalHeight = heroHeaderView.frame.height

        // Setup ViewModel with all state
        let heroViewModel = HeroHeader.ViewModel(controller: self, configuration: configuration)
        heroViewModel.delegate = heroHeaderDelegate
        heroViewModel.storedTitle = navigationItem.title ?? title

        let layout = HeroHeader.Layout(
            headerTopConstraint: constraints.top,
            headerHeightConstraint: constraints.height,
            contentHeightConstraint: contentConstraint,
            totalHeight: totalHeight
        )
        heroViewModel.setup(headerView: heroHeaderView, layout: layout)
        viewModel = heroViewModel

        let navBarHeight = navigationController?.navigationBar.frame.maxY ?? 88
        configureScrollViewInsets(scrollView, headerHeight: totalHeight, navBarHeight: navBarHeight)
    }

    private func createHeroHeaderView(
        contentView: UIView,
        configuration: HeroHeader.HeaderViewConfiguration
    ) -> (headerView: HeroHeaderView, contentConstraint: NSLayoutConstraint) {
        // contentView with height constraint (adjusted during stretch)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentConstraint = contentView.heightAnchor
            .constraint(equalToConstant: configuration.height)
        contentConstraint.isActive = true

        // Optional: Create large title view
        var largeTitleView: UIView?
        if case let .belowHeader(titleConfig) = configuration.largeTitleDisplayMode,
           let title = navigationItem.title ?? title
        {
            largeTitleView = UIView.largeTitleLabel(
                title,
                allowsLineWrap: titleConfig.allowsLineWrap
            )
        }

        let headerView = HeroHeaderView(contentView: contentView, largeTitleView: largeTitleView)

        if case .inline = configuration.largeTitleDisplayMode,
           let title = navigationItem.title ?? title
        {
            let inlineTitle = addInlineTitleLabel(title, to: contentView)
            headerView.largeTitleView = inlineTitle
        }

        return (headerView, contentConstraint)
    }

    @discardableResult
    private func addInlineTitleLabel(_ title: String, to contentView: UIView) -> LargeTitleView {
        let hasFog = contentView.backgroundColor != nil
        let fogColor = contentView.backgroundColor ?? .systemBackground
        let titleView = LargeTitleView(
            title: title,
            foregroundColor: .white,
            fog: hasFog,
            fogColor: fogColor
        )
        titleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            titleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
        return titleView
    }

    private func createOpaqueHeaderView(
        title _: String,
        backgroundColor: UIColor,
        foregroundColor _: UIColor?
    ) -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = backgroundColor
        return headerView
    }
}

extension UIViewController {
    func layoutHeaderView(_ headerView: UIView)
    -> (top: NSLayoutConstraint, height: NSLayoutConstraint) {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        let topConstraint = headerView.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Perform layout to calculate intrinsic height
        view.layoutIfNeeded()

        // Set height constraint (for collapse/stretch animations)
        let heightConstraint = headerView.heightAnchor
            .constraint(equalToConstant: headerView.frame.height)
        heightConstraint.isActive = true

        return (top: topConstraint, height: heightConstraint)
    }
}

extension UIViewController {
    func configureTransparentNavigationBar() {
        guard let navigationController else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.compactScrollEdgeAppearance = appearance
    }

    private func configureScrollViewInsets(
        _ scrollView: UIScrollView,
        headerHeight: CGFloat,
        navBarHeight: CGFloat
    ) {
        let insetTop = headerHeight - navBarHeight
        scrollView.contentInset = UIEdgeInsets(top: insetTop, left: 0, bottom: 0, right: 0)
        scrollView.setContentOffset(CGPoint(x: 0, y: -headerHeight), animated: false)
    }

    private func setupOpaqueHeader(
        backgroundColor: UIColor,
        foregroundColor: UIColor?,
        prefersLargeTitles: Bool
    ) throws {
        guard let navigationController else { throw HeroHeader.Error.navigationControllerNotFound }

        if #available(iOS 26, *), prefersLargeTitles {
            guard let title = navigationItem.title else {
                throw HeroHeader.Error.titleNotFound
            }
            try setupLargeTitleOpaqueHeaderCompatibleMode(
                title: title,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        } else {
            // Pre-iOS 26: use standard large title API
            navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles

            let appearance = UINavigationBarAppearance.withStyle(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
            let scrollEdgeAppearance = UINavigationBarAppearance.withStyle(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )

            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
            navigationController.navigationBar.compactScrollEdgeAppearance = scrollEdgeAppearance
        }
    }

    private func setupLargeTitleOpaqueHeaderCompatibleMode(
        title: String,
        backgroundColor: UIColor,
        foregroundColor: UIColor?
    ) throws {
        guard let scrollView = findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }
        // iOS 26+ does not play nicely with large titles when navbar has a background color
        let headerView = createOpaqueHeaderView(
            title: title,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )

        let configuration = HeroHeader.HeaderViewConfiguration(
            height: navigationbarHeightExtended,
            minHeight: navigationBarHeight,
            stretches: true,
            largeTitleDisplayMode: .inline
        )

        setupHeaderView(
            headerView,
            configuration: configuration,
            scrollView: scrollView
        )

        // Match nav bar small title color to header foreground
        if let foregroundColor {
            let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: foregroundColor]
            navigationController?.navigationBar.standardAppearance.titleTextAttributes = attrs
            navigationController?.navigationBar.scrollEdgeAppearance?.titleTextAttributes = attrs
            navigationController?.navigationBar.compactAppearance?.titleTextAttributes = attrs
            navigationController?.navigationBar.compactScrollEdgeAppearance?
                .titleTextAttributes = attrs
        }
    }

    private var navigationBarHeight: CGFloat {
        return navigationController?.navigationBar.frame.maxY ?? 88
    }

    private var navigationbarHeightExtended: CGFloat {
        return navigationBarHeight + 59
    }

}

// MARK: - ViewModel (internal for testing)

extension UIViewController {
    private enum ViewModelKey {
        nonisolated(unsafe) static var viewModel: Void?
    }

    var viewModel: HeroHeader.ViewModel? {
        get {
            objc_getAssociatedObject(self, &ViewModelKey.viewModel) as? HeroHeader.ViewModel
        }
        set {
            objc_setAssociatedObject(
                self,
                &ViewModelKey.viewModel,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

private extension UIViewController {

    enum AssociatedKeys {
        nonisolated(unsafe) static var scrollCancellable: Void?
        nonisolated(unsafe) static var heroHeaderDelegate: Void?
    }

    /// Stores delegate before setHeader() is called. Once ViewModel exists, delegate is stored
    /// there.
    var heroHeaderDelegate: HeroHeaderDelegate? {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys.heroHeaderDelegate
            ) as? HeroHeaderDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.heroHeaderDelegate,
                newValue,
                .OBJC_ASSOCIATION_ASSIGN
            )
        }
    }

    var scrollCancellable: AnyCancellable? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.scrollCancellable) as? AnyCancellable }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.scrollCancellable,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    func subscribeToScrollOffset(of scrollView: UIScrollView) {
        scrollCancellable = scrollView.publisher(for: \.contentOffset)
            .sink { [weak self] offset in
                self?.viewModel?.didScroll(offset: offset.y)
            }
    }

    func cleanupExistingHeader() {
        // Remove existing header view from hierarchy
        viewModel?.headerView?.removeFromSuperview()

        // Cancel scroll subscription
        scrollCancellable = nil

        // Clear viewModel
        viewModel = nil
    }

}
