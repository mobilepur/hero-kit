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
        case let .opaque(
            titleConfig,
            backgroundColor,
            foregroundColor,
            prefersLargeTitles,
            lightModeOnly
        ):
            try setupOpaqueHeader(
                titleConfig: titleConfig,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles,
                lightModeOnly: lightModeOnly
            )
        case let .headerView(view, _, _):
            setupHeaderView(
                view,
                style: style,
                scrollView: scrollView
            )
        }
    }

    private func setupHeaderView(
        _ contentView: UIView,
        style: HeroHeader.Style,
        scrollView: UIScrollView
    ) {
        guard let configuration = style.headerViewConfiguration else { return }
        configureTransparentNavigationBar()

        let (heroHeaderView, contentConstraint) = createHeroHeaderView(
            contentView: contentView,
            configuration: configuration,
            title: style.largeTitle,
            subtite: style.largeSubtitle
        )

        let constraints = layoutHeaderView(heroHeaderView)
        let totalHeight = heroHeaderView.frame.height

        // Setup ViewModel with all state
        let heroViewModel = HeroHeader.ViewModel(controller: self, style: style)
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
        let navBarHeight = navigationController?.navbarHeight ?? 88
        configureScrollViewInsets(scrollView, headerHeight: totalHeight, navBarHeight: navBarHeight)
    }

    private func createHeroHeaderView(
        contentView: UIView,
        configuration: HeroHeader.HeaderViewConfiguration,
        title: String?,
        subtite: String?
    ) -> (headerView: HeroHeaderView, contentConstraint: NSLayoutConstraint) {
        // contentView with height constraint (adjusted during stretch)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentConstraint = contentView.heightAnchor
            .constraint(equalToConstant: configuration.height)
        contentConstraint.isActive = true

        // Optional: Create large title view
        var largeTitleView: UIView?
        if case let .belowHeader(titleConfig) = configuration.largeTitleDisplayMode,
           let title
        {
            largeTitleView = UIView.largeTitleLabel(
                title: title,
                subtitle: subtite,
                allowsLineWrap: titleConfig.allowsLineWrap
            )
        }

        let headerView = HeroHeaderView(contentView: contentView, largeTitleView: largeTitleView)

        if case let .inline(inlineConfig) = configuration.largeTitleDisplayMode,
           let title = navigationItem.title ?? title
        {
            let inlineTitle = addInlineTitleLabel(
                title,
                dimming: inlineConfig.dimming,
                to: contentView
            )
            headerView.largeTitleView = inlineTitle
        }

        return (headerView, contentConstraint)
    }

    @discardableResult
    private func addInlineTitleLabel(
        _ title: String,
        dimming: HeroHeader.InlineTitleConfiguration.Dimming,
        to contentView: UIView
    ) -> LargeTitleView {
        let hasFog = contentView.backgroundColor != nil
        let fogColor = contentView.backgroundColor ?? .systemBackground
        let titleView = LargeTitleView(
            title: title,
            foregroundColor: .white,
            fog: hasFog,
            fogColor: fogColor
        )
        titleView.translatesAutoresizingMaskIntoConstraints = false

        // Add dimming overlay for readability on bright images
        switch dimming {
        case .none:
            break
        case .complete:
            let dimmingView = createDimmingView(gradient: false)
            contentView.addSubview(dimmingView)
            pinToEdges(dimmingView, in: contentView)
        case .gradient:
            let dimmingView = createDimmingView(gradient: true)
            contentView.addSubview(dimmingView)
            pinToEdges(dimmingView, in: contentView)
        }

        contentView.addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            titleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
        return titleView
    }

    private func createDimmingView(gradient: Bool) -> UIView {
        if gradient {
            let dimmingView = GradientDimmingView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.isUserInteractionEnabled = false
            return dimmingView
        } else {
            let dimmingView = UIView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.isUserInteractionEnabled = false
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            return dimmingView
        }
    }

    private func pinToEdges(_ subview: UIView, in parent: UIView) {
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: parent.topAnchor),
            subview.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
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

    private func configureScrollViewInsets(
        _ scrollView: UIScrollView,
        headerHeight: CGFloat,
        navBarHeight: CGFloat
    ) {
        let insetTop = headerHeight - navBarHeight
        scrollView.contentInset = UIEdgeInsets(top: insetTop, left: 0, bottom: 0, right: 0)

        // Defer setting contentOffset until after layout pass completes
        // to avoid iOS adjusting it when safeAreaInsets are applied
        let targetOffset = CGPoint(x: 0, y: -headerHeight)
        DispatchQueue.main.async { [weak self] in
            scrollView.setContentOffset(targetOffset, animated: false)
            self?.viewModel?.didCompleteSetup()
        }
    }

    private func setupOpaqueHeader(
        titleConfig: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor?,
        prefersLargeTitles: Bool,
        lightModeOnly: Bool
    ) throws {
        guard let navigationController else { throw HeroHeader.Error.navigationControllerNotFound }

        // Resolve title from config, falling back to navigationItem.title or self.title
        let resolvedTitle = titleConfig.largeTitle ?? titleConfig.title ?? navigationItem
            .title ?? title

        // In dark mode with lightModeOnly, use default system appearance
        if lightModeOnly, isDarkMode {
            // On iOS 26+, native large titles don't work, so we still need our headerView
            if #available(iOS 26, *), prefersLargeTitles {
                guard let _ = resolvedTitle else {
                    throw HeroHeader.Error.titleNotFound
                }
                guard let scrollView = findScrollView() else {
                    throw HeroHeader.Error.scrollViewNotFound
                }
                // Create transparent header with inline title for dark mode
                let headerView = UIView()
                headerView.backgroundColor = .clear
                let configuration = HeroHeader.HeaderViewConfiguration(
                    height: navigationbarHeightExtended,
                    minHeight: navigationBarHeight,
                    stretches: true,
                    largeTitleDisplayMode: .inline()
                )
                let style = HeroHeader.Style.headerView(
                    view: headerView,
                    configuration: configuration,
                    title: titleConfig
                )
                setupHeaderView(headerView, style: style, scrollView: scrollView)
            } else {
                // Pre-iOS 26: system large titles work fine
                configureDefaultNavigationBar()
                navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
            }
            return
        }

        if #available(iOS 26, *), prefersLargeTitles {
            guard let title = resolvedTitle else {
                throw HeroHeader.Error.titleNotFound
            }
            try setupLargeTitleOpaqueHeaderCompatibleMode(
                title: title,
                titleConfig: titleConfig,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        } else {
            // Pre-iOS 26: use standard large title API
            navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
            configureOpaqueNavigationBar(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        }
    }

    /*
     iOS 26 workaround to replicate pre liquid glass behaviour
     */
    private func setupLargeTitleOpaqueHeaderCompatibleMode(
        title: String,
        titleConfig: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor?
    ) throws {
        guard let scrollView = findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }
        let headerView = createOpaqueHeaderView(
            title: title,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )

        let configuration = HeroHeader.HeaderViewConfiguration(
            height: navigationbarHeightExtended,
            minHeight: navigationBarHeight,
            stretches: true,
            largeTitleDisplayMode: .inline()
        )

        let style = HeroHeader.Style.headerView(
            view: headerView,
            configuration: configuration,
            title: titleConfig
        )

        setupHeaderView(
            headerView,
            style: style,
            scrollView: scrollView
        )

        // Match nav bar small title color to header foreground
        if let foregroundColor {
            setNavigationBarTitleColor(foregroundColor)
            setNavigationBarSubtitleColor(foregroundColor.withAlphaComponent(0.75))
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
