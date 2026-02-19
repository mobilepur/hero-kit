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
        case let .image(url, contentMode, backgroundColor, loadingType, _, _):
            let imageView = AsyncHeaderImageView(
                url: url,
                contentMode: contentMode,
                backgroundColor: backgroundColor,
                loadingType: loadingType
            )
            setupHeaderView(
                imageView,
                style: style,
                scrollView: scrollView
            )
        }
    }

    private func setupHeaderView(
        _ contentView: UIView,
        style: HeroHeader.Style,
        scrollView: UIScrollView,
        foregroundColor: UIColor? = nil
    ) {
        guard let configuration = style.headerViewConfiguration else { return }
        configureTransparentNavigationBar()

        let (heroHeaderView, contentConstraint) = createHeroHeaderView(
            contentView: contentView,
            configuration: configuration,
            title: style.largeTitle,
            subtitle: style.largeSubtitle,
            foregroundColor: foregroundColor ?? style.foregroundColor
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
        subtitle: String?,
        foregroundColor: UIColor?
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
                subtitle: subtitle,
                allowsLineWrap: titleConfig.allowsLineWrap,
                insets: titleConfig.insets
            )
        }

        let headerView = HeroHeaderView(contentView: contentView, largeTitleView: largeTitleView)

        if case let .inline(inlineConfig) = configuration.largeTitleDisplayMode,
           let title
        {
            let inlineTitle = contentView.addInlineTitleLabel(
                title: title,
                subtitle: subtitle,
                foregroundColor: foregroundColor ?? .white,
                dimming: inlineConfig.dimming,
                insets: inlineConfig.insets
            )
            headerView.largeTitleView = inlineTitle
        }

        return (headerView, contentConstraint)
    }

    private func createOpaqueHeaderView(
        backgroundColor: UIColor
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
        try applyOpaqueAppearance(
            titleConfig: titleConfig,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            prefersLargeTitles: prefersLargeTitles,
            lightModeOnly: lightModeOnly
        )

        if lightModeOnly {
            registerOpaqueStyleTraitObserver(
                titleConfig: titleConfig,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles
            )
        }
    }

    private func applyOpaqueAppearance(
        titleConfig: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor?,
        prefersLargeTitles: Bool,
        lightModeOnly: Bool
    ) throws {
        guard let navigationController else { throw HeroHeader.Error.navigationControllerNotFound }

        if lightModeOnly, isDarkMode {
            if #available(iOS 26, *), prefersLargeTitles {
                try setupLargeTitleOpaqueHeaderCompatibleMode(
                    titleConfig: titleConfig,
                    backgroundColor: .clear,
                    foregroundColor: nil
                )
            } else {
                configureDefaultNavigationBar()
                navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
            }
        } else if #available(iOS 26, *), prefersLargeTitles {
            try setupLargeTitleOpaqueHeaderCompatibleMode(
                titleConfig: titleConfig,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        } else {
            navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
            configureOpaqueNavigationBar(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor
            )
        }
    }

    private func registerOpaqueStyleTraitObserver(
        titleConfig: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor?,
        prefersLargeTitles: Bool
    ) {
        if let existing = traitRegistration {
            unregisterForTraitChanges(existing)
        }

        traitRegistration = registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (vc: UIViewController, _: UITraitCollection) in
            vc.viewModel?.headerView?.removeFromSuperview()
            vc.scrollCancellable = nil
            vc.viewModel = nil

            try? vc.applyOpaqueAppearance(
                titleConfig: titleConfig,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles,
                lightModeOnly: true
            )

            // Re-subscribe to scroll if headerView was created (iOS 26+ path)
            if vc.viewModel != nil, let scrollView = vc.findScrollView() {
                vc.subscribeToScrollOffset(of: scrollView)
            }
        }
    }

    /**
     iOS 26 workaround to replicate pre liquid glass behaviour
     */
    private func setupLargeTitleOpaqueHeaderCompatibleMode(
        titleConfig: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor?
    ) throws {
        guard let resolvedTitle = resolveTitle(from: titleConfig) else {
            throw HeroHeader.Error.titleNotFound
        }
        guard let scrollView = findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }
        let headerView = createOpaqueHeaderView(
            backgroundColor: backgroundColor
        )

        let resolvedSubtitle = titleConfig.largeSubtitle ?? titleConfig.subtitle
        let largeTitleHeight = measureInlineTitleHeight(
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            foregroundColor: foregroundColor ?? .label
        )
        let contentHeight = navigationBarHeight + largeTitleHeight

        let configuration = HeroHeader.HeaderViewConfiguration(
            height: contentHeight,
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
            scrollView: scrollView,
            foregroundColor: foregroundColor
        )

        // Match nav bar small title color to header foreground
        if let foregroundColor {
            setNavigationBarTitleColor(foregroundColor)
            setNavigationBarSubtitleColor(foregroundColor.withAlphaComponent(0.75))
        }
    }

    private func resolveTitle(from titleConfig: HeroHeader.TitleConfiguration) -> String? {
        titleConfig.largeTitle ?? titleConfig.title ?? navigationItem.title ?? title
    }

    private var navigationBarHeight: CGFloat {
        return navigationController?.navigationBar.frame.maxY ?? 88
    }

    private func measureInlineTitleHeight(
        title: String,
        subtitle: String?,
        foregroundColor: UIColor
    ) -> CGFloat {
        let titleView = LargeTitleView(
            title: title,
            subtitle: subtitle,
            foregroundColor: foregroundColor,
            fog: false
        )
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        return titleView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
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

private final class WeakDelegateWrapper {
    weak var delegate: HeroHeaderDelegate?
    init(_ delegate: HeroHeaderDelegate) {
        self.delegate = delegate
    }
}

private extension UIViewController {

    enum AssociatedKeys {
        nonisolated(unsafe) static var scrollCancellable: Void?
        nonisolated(unsafe) static var heroHeaderDelegate: Void?
        nonisolated(unsafe) static var traitRegistration: Void?
    }

    /// Stores delegate before setHeader() is called. Once ViewModel exists, delegate is stored
    /// there. Uses a weak wrapper to avoid dangling pointer crashes with OBJC_ASSOCIATION_ASSIGN.
    var heroHeaderDelegate: HeroHeaderDelegate? {
        get {
            (objc_getAssociatedObject(
                self,
                &AssociatedKeys.heroHeaderDelegate
            ) as? WeakDelegateWrapper)?.delegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.heroHeaderDelegate,
                newValue.map { WeakDelegateWrapper($0) },
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
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

    var traitRegistration: UITraitChangeRegistration? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys
                                         .traitRegistration) as? UITraitChangeRegistration
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.traitRegistration,
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

        // Unregister trait observation
        if let registration = traitRegistration {
            unregisterForTraitChanges(registration)
            traitRegistration = nil
        }
    }

}
