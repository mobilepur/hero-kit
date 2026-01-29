import Combine
import ObjectiveC
import UIKit

// MARK: - UIViewController Extension

public extension UIViewController {

    func configureHeader(_ style: HeroHeader.Style, scrollView: UIScrollView? = nil) throws {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }

        try setupHeader(style: style, scrollView: targetScrollView)
        subscribeToScrollOffset(of: targetScrollView)
    }

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) throws {
        switch style {
        case let .color(backgroundColor, foregroundColor):
            try styleHeader(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
        case let .headerView(view, configuration):
            setupHeaderView(view, configuration: configuration, scrollView: scrollView)
        }
    }

    private func setupHeaderView(
        _ headerView: UIView,
        configuration: HeroHeader.HeaderViewConfiguration,
        scrollView: UIScrollView
    ) {
        configureTransparentNavigationBar()

        let (stackView, contentConstraint) = createHeaderStackView(
            headerView: headerView,
            configuration: configuration
        )
        heroHeaderView = stackView
        contentHeightConstraint = contentConstraint

        let constraints = layoutHeaderView(stackView)
        headerTopConstraint = constraints.top
        headerHeightConstraint = constraints.height

        let totalHeight = stackView.frame.height
        let navBarHeight = navigationController?.navigationBar.frame.maxY ?? 88

        print("DEBUG setupHeaderView:")
        print("  - totalHeight: \(totalHeight)")
        print("  - navBarHeight: \(navBarHeight)")
        print("  - insetTop: \(totalHeight - navBarHeight)")
        print("  - scrollView.frame: \(scrollView.frame)")

        configureScrollViewInsets(scrollView, headerHeight: totalHeight, navBarHeight: navBarHeight)

        print("DEBUG after: contentOffset.y = \(scrollView.contentOffset.y)")

        headerConfiguration = configuration
        headerTotalHeight = totalHeight
    }

    private func createHeaderStackView(
        headerView: UIView,
        configuration: HeroHeader.HeaderViewConfiguration
    ) -> (stackView: UIStackView, contentConstraint: NSLayoutConstraint) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.clipsToBounds = true

        // headerView mit Höhen-Constraint (wird beim Stretch angepasst)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let contentConstraint = headerView.heightAnchor
            .constraint(equalToConstant: configuration.height)
        contentConstraint.isActive = true
        stackView.addArrangedSubview(headerView)

        // Optional: Large Title hinzufügen
        if case let .belowHeader(titleConfig) = configuration.largeTitleDisplayMode,
           let title = navigationItem.title ?? title
        {
            let largeTitleView = UIView.largeTitleLabel(
                title,
                allowsLineWrap: titleConfig.allowsLineWrap
            )
            stackView.addArrangedSubview(largeTitleView)
        }

        return (stackView, contentConstraint)
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

        // Layout durchführen um intrinsische Höhe zu berechnen
        view.layoutIfNeeded()

        // Jetzt Höhen-Constraint setzen (für spätere Collapse/Stretch Animationen)
        let heightConstraint = headerView.heightAnchor
            .constraint(equalToConstant: headerView.frame.height)
        heightConstraint.isActive = true

        print("DEBUG layoutHeaderView: frame.height = \(headerView.frame.height)")
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

    private enum AssociatedKeys {
        nonisolated(unsafe) static var scrollCancellable: Void?
        nonisolated(unsafe) static var scrollOffset: Void?
        nonisolated(unsafe) static var headerView: Void?
        nonisolated(unsafe) static var headerTopConstraint: Void?
        nonisolated(unsafe) static var headerHeightConstraint: Void?
        nonisolated(unsafe) static var contentHeightConstraint: Void?
        nonisolated(unsafe) static var headerConfiguration: Void?
        nonisolated(unsafe) static var headerTotalHeight: Void?
    }

    private var heroHeaderView: UIView? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.headerView) as? UIView }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.headerView,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    private var headerTopConstraint: NSLayoutConstraint? {
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

    private var headerHeightConstraint: NSLayoutConstraint? {
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

    private var contentHeightConstraint: NSLayoutConstraint? {
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

    private var scrollCancellable: AnyCancellable? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.scrollCancellable) as? AnyCancellable }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.scrollCancellable,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    private(set) var heroScrollOffset: CGFloat {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.scrollOffset) as? CGFloat) ?? 0 }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.scrollOffset,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    private var headerConfiguration: HeroHeader.HeaderViewConfiguration? {
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

    private var headerTotalHeight: CGFloat {
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

    private func subscribeToScrollOffset(of scrollView: UIScrollView) {
        scrollCancellable = scrollView.publisher(for: \.contentOffset)
            .sink { [weak self] offset in
                self?.heroScrollOffset = offset.y
                self?.updateHeaderConstraints(for: offset.y)
            }
    }

    private func updateHeaderConstraints(for offsetY: CGFloat) {
        guard let configuration = headerConfiguration,
              let topConstraint = headerTopConstraint,
              let heightConstraint = headerHeightConstraint
        else { return }

        let invertedOffset = -offsetY
        let totalHeight = headerTotalHeight

        if invertedOffset > totalHeight, configuration.stretches {
            // Overscroll - stretch effect
            let stretchAmount = invertedOffset - totalHeight
            heightConstraint.constant = invertedOffset
            contentHeightConstraint?.constant = configuration.height + stretchAmount
            topConstraint.constant = 0
        } else if invertedOffset < totalHeight {
            // Header collapsing
            let minOffset = max(configuration.minHeight ?? 0, invertedOffset)
            topConstraint.constant = minOffset - totalHeight
            heightConstraint.constant = totalHeight
            contentHeightConstraint?.constant = configuration.height
        } else {
            // Normal expanded state
            topConstraint.constant = 0
            heightConstraint.constant = totalHeight
            contentHeightConstraint?.constant = configuration.height
        }
    }

}

/*

 https://stackoverflow.com/questions/79795513/navigation-header-disappears-with-custom-background-color-in-form-view-on-ios-26

 Form {
     // content as before
 }
 .scrollContentBackground(.hidden)
 .background {
     VStack(spacing: 0) {
         Color(red: 0.2, green: 0.5, blue: 0.7)
             .ignoresSafeArea()
             .frame(height: 0)
         Color(.systemGroupedBackground)
             .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
     }
 }
 .navigationTitle("Scanner Settings")
 .navigationBarTitleDisplayMode(.large)
 .toolbarBackground(.visible, for: .navigationBar)
 */

/*
 struct CustomNavigationBarModifier: ViewModifier {
     init() {
         let appearance = UINavigationBarAppearance()
         appearance.configureWithOpaqueBackground()
         if #unavailable(iOS 26.0) {
             // Set backgroundColor only for versions below iOS 26.0
             appearance.backgroundColor = .green
         }
         appearance.largeTitleTextAttributes = [
             .font: UIFont.systemFont(ofSize: 30, weight: .heavy),
             .foregroundColor: UIColor.black,
         ]
         appearance.titleTextAttributes = [
             .font: UIFont.systemFont(ofSize: 15, weight: .regular),
             .foregroundColor: UIColor.black,
         ]
         UINavigationBar.appearance().standardAppearance = appearance
         UINavigationBar.appearance().scrollEdgeAppearance = appearance
     }

     func body(content: Content) -> some View {
         if #available(iOS 26, *) {
             // Use toolbarBackground for iOS 26.0 and later
             content
                 .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                 .toolbarBackground(.green, for: .navigationBar)
         } else {
             content
         }
     }
 }

 extension View {
     func defaultNavigationBar() -> some View {
         modifier(CustomNavigationBarModifier())
     }
 }

 */
