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
        // TODO: Implement
    }

    /// Collapses header content - large title still visible (if present)
    func collapseHeaderContent(animated: Bool = true) {
        // TODO: Implement
    }

    /// Collapses the header fully - only nav bar visible
    func collapseHeader(animated: Bool = true) {
        // TODO: Implement
    }
}

// MARK: - helper

extension UIViewController {

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) throws {
        switch style {
        case let .color(backgroundColor, foregroundColor):
            try styleHeader(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
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
        return (headerView, contentConstraint)
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

    private func styleHeader(backgroundColor: UIColor, foregroundColor: UIColor?) throws {
        guard let navigationController else { throw HeroHeader.Error.navigationControllerNotFound }
        // for now large titles with colored backgrounds are not supported in iOS 26
        if #available(iOS 26, *) {
            navigationItem.largeTitleDisplayMode = .inline
            navigationController.navigationBar.prefersLargeTitles = false
        }

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

    /// Stores delegate before setHeader() is called. Once ViewModel exists, delegate is stored there.
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

