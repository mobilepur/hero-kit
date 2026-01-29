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
        print("HeroKit: Configuring header with style: \(style)")
        print("HeroKit: Subscribed to scroll view: \(targetScrollView)")
    }

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) throws {
        switch style {
        case let .color(backgroundColor, foregroundColor):
            try styleHeader(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
        case let .headerView(view, height, minHeight):
            setupHeaderView(view, height: height, minHeight: minHeight, scrollView: scrollView)
        }
    }

    private func setupHeaderView(
        _ headerView: UIView,
        height: CGFloat,
        minHeight: CGFloat?,
        scrollView _: UIScrollView
    ) {
        // TODO: Implement collapsable header view
        print(
            "HeroKit: headerView style not yet implemented - view: \(headerView), height: \(height), minHeight: \(String(describing: minHeight))"
        )
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
        nonisolated(unsafe) static var headerBottomConstraint: Void?
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

    private var headerBottomConstraint: NSLayoutConstraint? {
        get {
            objc_getAssociatedObject(self,
                                     &AssociatedKeys.headerBottomConstraint) as? NSLayoutConstraint
        }
        set { objc_setAssociatedObject(
            self,
            &AssociatedKeys.headerBottomConstraint,
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

    private func subscribeToScrollOffset(of scrollView: UIScrollView) {
        scrollCancellable = scrollView.publisher(for: \.contentOffset)
            .sink { [weak self] offset in
                self?.heroScrollOffset = offset.y
                self?.updateHeaderConstraints(for: offset.y)
            }
    }

    private func updateHeaderConstraints(for _: CGFloat) { }

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
