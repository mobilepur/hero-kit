import Combine
import ObjectiveC
import UIKit

// MARK: - UIViewController Extension

public extension UIViewController {

    var headerDelegate: HeroHeaderDelegate? {
        get { heroHeaderDelegate }
        set { heroHeaderDelegate = newValue }
    }

    func configureHeader(_ style: HeroHeader.Style, scrollView: UIScrollView? = nil) throws {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }

        try setupHeader(style: style, scrollView: targetScrollView)
        subscribeToScrollOffset(of: targetScrollView)
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
        headerContainer = heroHeaderView
        contentHeightConstraint = contentConstraint

        let constraints = layoutHeaderView(heroHeaderView)
        headerTopConstraint = constraints.top
        headerHeightConstraint = constraints.height

        let totalHeight = heroHeaderView.frame.height

        // Setup ViewModel
        let heroViewModel = HeroHeader.ViewModel(controller: self, configuration: configuration)
        heroViewModel.delegate = heroHeaderDelegate
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
        headerConfiguration = configuration
        headerTotalHeight = totalHeight

        // Store title and apply initial small title visibility
        storedTitle = navigationItem.title ?? title
        applySmallTitleVisibility(for: configuration.smallTitleDisplayMode, isCollapsed: false)
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

    func applySmallTitleVisibility(
        for mode: HeroHeader.SmallTitleDisplayMode,
        isCollapsed: Bool,
        isLargeTitleHidden: Bool = false
    ) {
        let shouldShow: Bool = switch mode {
        case .never:
            false
        case .always:
            true
        case .whenHeaderCollapsed:
            isCollapsed
        case .whenLargeTitleHidden:
            isLargeTitleHidden
        }
        navigationItem.title = shouldShow ? storedTitle : nil
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
        nonisolated(unsafe) static var scrollOffset: Void?
        nonisolated(unsafe) static var headerContainer: Void?
        nonisolated(unsafe) static var headerTopConstraint: Void?
        nonisolated(unsafe) static var headerHeightConstraint: Void?
        nonisolated(unsafe) static var contentHeightConstraint: Void?
        nonisolated(unsafe) static var headerConfiguration: Void?
        nonisolated(unsafe) static var headerTotalHeight: Void?
        nonisolated(unsafe) static var heroHeaderDelegate: Void?
        nonisolated(unsafe) static var storedTitle: Void?
    }

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

    var headerContainer: HeroHeaderView? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.headerContainer) as? HeroHeaderView }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.headerContainer,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    var headerTopConstraint: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys.headerTopConstraint) as? NSLayoutConstraint
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.headerTopConstraint,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    var headerHeightConstraint: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys.headerHeightConstraint) as? NSLayoutConstraint
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.headerHeightConstraint,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    var contentHeightConstraint: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys.contentHeightConstraint) as? NSLayoutConstraint
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.contentHeightConstraint,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
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

    var heroScrollOffset: CGFloat {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.scrollOffset) as? CGFloat) ?? 0 }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.scrollOffset,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    var headerConfiguration: HeroHeader.HeaderViewConfiguration? {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys.headerConfiguration
            ) as? HeroHeader.HeaderViewConfiguration
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.headerConfiguration,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var headerTotalHeight: CGFloat {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.headerTotalHeight) as? CGFloat) ?? 0 }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.headerTotalHeight,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var storedTitle: String? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.storedTitle) as? String }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.storedTitle,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    func subscribeToScrollOffset(of scrollView: UIScrollView) {
        scrollCancellable = scrollView.publisher(for: \.contentOffset)
            .sink { [weak self] offset in
                self?.heroScrollOffset = offset.y
                self?.updateHeaderConstraints(for: offset.y)
            }
    }

    func updateHeaderConstraints(for offsetY: CGFloat) {
        guard let configuration = headerConfiguration,
              let topConstraint = headerTopConstraint,
              let heightConstraint = headerHeightConstraint,
              let headerView = headerContainer
        else { return }

        let invertedOffset = -offsetY
        let totalHeight = headerTotalHeight
        let effectiveMinHeight = configuration.minHeight ?? 0

        if invertedOffset > totalHeight, configuration.stretches {
            // Overscroll - stretch effect
            let stretchAmount = invertedOffset - totalHeight
            heightConstraint.constant = invertedOffset
            contentHeightConstraint?.constant = configuration.height + stretchAmount
            topConstraint.constant = 0

            // didStretch
            if !headerView.isStretching {
                headerView.isStretching = true
                // heroHeaderDelegate?.heroHeader(self, didStretch: headerView)
            }

            // Large title visible, header not collapsed when stretching
            if headerView.isLargeTitleHidden {
                headerView.isLargeTitleHidden = false
            }
            applySmallTitleVisibility(
                for: configuration.smallTitleDisplayMode,
                isCollapsed: false,
                isLargeTitleHidden: false
            )

        } else if invertedOffset < totalHeight {
            // Header collapsing
            let minOffset = max(effectiveMinHeight, invertedOffset)
            topConstraint.constant = minOffset - totalHeight
            heightConstraint.constant = totalHeight
            contentHeightConstraint?.constant = configuration.height

            // didUnstretch
            if headerView.isStretching {
                headerView.isStretching = false
                // heroHeaderDelegate?.heroHeader(self, didUnstretch: headerView)
            }

            // didCollapse / didBecameVisible
            let isNowCollapsed = invertedOffset <= effectiveMinHeight
            if isNowCollapsed != headerView.isCollapsed {
                headerView.isCollapsed = isNowCollapsed
                // if isNowCollapsed {
                //     heroHeaderDelegate?.heroHeader(self, didCollapse: headerView)
                // } else {
                //     heroHeaderDelegate?.heroHeader(self, didBecameVisible: headerView)
                // }
            }

            // Track large title visibility (hidden when scrolled behind nav bar)
            let isNowLargeTitleHidden = invertedOffset < configuration.height
            if isNowLargeTitleHidden != headerView.isLargeTitleHidden {
                headerView.isLargeTitleHidden = isNowLargeTitleHidden
            }

            // Update small title visibility
            applySmallTitleVisibility(
                for: configuration.smallTitleDisplayMode,
                isCollapsed: headerView.isCollapsed,
                isLargeTitleHidden: headerView.isLargeTitleHidden
            )

            // No longer fully expanded
            if headerView.isFullyExpanded {
                headerView.isFullyExpanded = false
            }

        } else {
            // Normal expanded state
            topConstraint.constant = 0
            heightConstraint.constant = totalHeight
            contentHeightConstraint?.constant = configuration.height

            // didUnstretch
            if headerView.isStretching {
                headerView.isStretching = false
                // heroHeaderDelegate?.heroHeader(self, didUnstretch: headerView)
            }

            // didExpandFully
            if !headerView.isFullyExpanded {
                headerView.isFullyExpanded = true
                // heroHeaderDelegate?.heroHeader(self, didExpandFully: headerView)
            }

            // Large title visible, not collapsed when fully expanded
            if headerView.isLargeTitleHidden {
                headerView.isLargeTitleHidden = false
            }
            applySmallTitleVisibility(
                for: configuration.smallTitleDisplayMode,
                isCollapsed: false,
                isLargeTitleHidden: false
            )
        }

        let normalizedOffset = offsetY + totalHeight
        viewModel?.didScroll(offset: normalizedOffset)
    }

}

