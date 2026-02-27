import Combine
import ObjectiveC
import os
import UIKit

private func heroWarning(_ message: String) {
    #if DEBUG
        os_log(
            .fault,
            log: OSLog(subsystem: "com.apple.runtime-issues", category: "HeroKit"),
            "%{public}s",
            message
        )
    #endif
}

// MARK: - UIViewController Extension

public extension UIViewController {

    /// Presents the destination modally with a matched-element transition.
    ///
    /// The source view's image morphs into the destination's header image.
    /// On dismiss, the animation reverses automatically.
    func heroPresent(
        _ destination: UIViewController,
        source: any HeroTransitionSource,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let transitionDelegate = HeroMatchedTransitionDelegate(source: source)
        destination.heroTransitionDelegate = transitionDelegate
        destination.transitioningDelegate = transitionDelegate
        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: animated, completion: completion)
    }

    var headerDelegate: HeroHeaderDelegate? {
        get { viewModel?.delegate ?? heroHeaderDelegate }
        set {
            heroHeaderDelegate = newValue
            viewModel?.delegate = newValue
        }
    }

    func setHeader(
        _ style: HeroHeader.Style,
        restoresOnAppear: Bool = true,
        scrollView: UIScrollView? = nil
    ) {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            heroWarning(
                "No UIScrollView found. Pass a scrollView parameter or ensure one exists in the view hierarchy."
            )
            return
        }

        // Clean up existing header if present
        cleanupExistingHeader()

        setupHeader(style: style, scrollView: targetScrollView)
        subscribeToScrollOffset(of: targetScrollView)

        if restoresOnAppear {
            installAppearanceObserver()
        }
    }

    func setHeader(
        view: UIView,
        configuration: HeroHeader.HeaderViewConfiguration = .init(),
        title: HeroHeader.TitleConfiguration? = nil,
        restoresOnAppear: Bool = true,
        scrollView: UIScrollView? = nil
    ) {
        setHeader(
            .headerView(view: view, configuration: configuration, title: title),
            restoresOnAppear: restoresOnAppear,
            scrollView: scrollView
        )
    }

    func setImageHeader(
        url: URL,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        backgroundColor: UIColor? = nil,
        loadingType: HeroHeader.LoadingType = .spinner,
        configuration: HeroHeader.HeaderViewConfiguration = .init(),
        title: HeroHeader.TitleConfiguration? = nil,
        restoresOnAppear: Bool = true,
        scrollView: UIScrollView? = nil
    ) {
        let imageConfig = HeroHeader.ImageConfiguration(
            url: url,
            contentMode: contentMode,
            backgroundColor: backgroundColor,
            loadingType: loadingType
        )
        setHeader(
            .image(image: imageConfig, configuration: configuration, title: title),
            restoresOnAppear: restoresOnAppear,
            scrollView: scrollView
        )
    }

    func setOpaqueHeader(
        title: HeroHeader.TitleConfiguration,
        backgroundColor: UIColor,
        foregroundColor: UIColor? = nil,
        prefersLargeTitles: Bool = false,
        lightModeOnly: Bool = false,
        restoresOnAppear: Bool = true
    ) {
        setHeader(.opaque(
            title: title,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            prefersLargeTitles: prefersLargeTitles,
            lightModeOnly: lightModeOnly
        ), restoresOnAppear: restoresOnAppear)
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

    /// Re-notifies the delegate about the current header state to restore navigation bar styling.
    func reapplyHeaderStyle() {
        viewModel?.reapplyState()
    }
}

// MARK: - helper

extension UIViewController {

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) {
        switch style {
        case let .opaque(
            titleConfig,
            backgroundColor,
            foregroundColor,
            prefersLargeTitles,
            lightModeOnly
        ):
            setupOpaqueHeader(
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
        case let .image(image: imageConfig, _, _):
            let imageView = AsyncHeaderImageView(
                url: imageConfig.url,
                contentMode: imageConfig.contentMode,
                backgroundColor: imageConfig.backgroundColor,
                loadingType: imageConfig.loadingType
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
        // Priority below required so it doesn't conflict with the stack view's
        // UIView-Encapsulated-Layout-Height during layout passes.
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentConstraint = contentView.heightAnchor
            .constraint(equalToConstant: configuration.height)
        contentConstraint.priority = .defaultHigh
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
                minimumScaleFactor: titleConfig.minimumScaleFactor,
                insets: titleConfig.insets,
                accessories: titleConfig.accessories
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
                minimumScaleFactor: inlineConfig.minimumScaleFactor,
                insets: inlineConfig.insets,
                accessories: inlineConfig.accessories
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
    ) {
        applyOpaqueAppearance(
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
    ) {
        guard let navigationController else {
            heroWarning(
                "No UINavigationController found. Opaque headers require a navigation controller."
            )
            return
        }

        if lightModeOnly, isDarkMode {
            if #available(iOS 26, *), prefersLargeTitles {
                setupLargeTitleOpaqueHeaderCompatibleMode(
                    titleConfig: titleConfig,
                    backgroundColor: .clear,
                    foregroundColor: nil
                )
            } else {
                configureDefaultNavigationBar()
                navigationController.navigationBar.prefersLargeTitles = prefersLargeTitles
            }
        } else if #available(iOS 26, *), prefersLargeTitles {
            setupLargeTitleOpaqueHeaderCompatibleMode(
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

            vc.applyOpaqueAppearance(
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
    ) {
        guard let resolvedTitle = resolveTitle(from: titleConfig) else {
            heroWarning(
                "No title found. Provide a title via TitleConfiguration or set navigationItem.title."
            )
            return
        }
        guard let scrollView = findScrollView() else {
            heroWarning(
                "No UIScrollView found. Pass a scrollView parameter or ensure one exists in the view hierarchy."
            )
            return
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

private final class AppearanceObserver: UIViewController {
    var onWillAppear: (() -> Void)?
    private var hasAppeared = false

    override func loadView() {
        view = UIView()
        view.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasAppeared {
            onWillAppear?()
        }
        hasAppeared = true
    }
}

private extension UIViewController {

    enum AssociatedKeys {
        nonisolated(unsafe) static var scrollCancellable: Void?
        nonisolated(unsafe) static var heroHeaderDelegate: Void?
        nonisolated(unsafe) static var traitRegistration: Void?
        nonisolated(unsafe) static var appearanceObserver: Void?
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

    var appearanceObserver: AppearanceObserver? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys.appearanceObserver) as? AppearanceObserver
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.appearanceObserver,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    func installAppearanceObserver() {
        guard viewModel != nil else { return }

        let observer = AppearanceObserver()
        observer.onWillAppear = { [weak self] in
            self?.viewModel?.reapplyState()
        }
        addChild(observer)
        view.addSubview(observer.view)
        observer.didMove(toParent: self)
        appearanceObserver = observer
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

        // Remove appearance observer
        if let observer = appearanceObserver {
            observer.willMove(toParent: nil)
            observer.view.removeFromSuperview()
            observer.removeFromParent()
            appearanceObserver = nil
        }
    }

}
