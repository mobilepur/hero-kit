import Combine
import ObjectiveC
import UIKit

// MARK: - Header Style

public enum HeroHeader {
    public enum Style {
        case color(UIColor)
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
    }
}

// MARK: - UIViewController Extension

public extension UIViewController {

    func configureHeader(_ style: HeroHeader.Style, scrollView: UIScrollView? = nil) throws {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            throw HeroHeader.Error.scrollViewNotFound
        }

        subscribeToScrollOffset(of: targetScrollView)
        setupHeader(style: style, scrollView: targetScrollView)
        print("HeroKit: Configuring header with style: \(style)")
        print("HeroKit: Subscribed to scroll view: \(targetScrollView)")
    }

    private func setupHeader(style: HeroHeader.Style, scrollView: UIScrollView) {
        // 1. Farbe aus Style extrahieren
        let headerColor: UIColor = switch style {
        case let .color(color):
            color
        }

        // 2. ScrollView Hintergrund verstecken (wie .scrollContentBackground(.hidden))
        scrollView.backgroundColor = .clear

        // 3. Header-View die nur den SafeArea-Bereich füllt
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(headerView, at: 0)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])

        heroHeaderView = headerView

        // 4. NavigationBar Appearance (wie .toolbarBackground(.visible))
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = headerColor

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        /*
         navigationController?.navigationBar.traverseSubviews(apply: { subview in
             print("New Subview ----------------------")
             print(type(of: subview), "\n")
             print(subview, "\n")
             print(subview.frame, "\n")
             print(subview.backgroundColor, "\n")
             subview.backgroundColor = subview.backgroundColor?.withAlphaComponent(0.3)
         })

         */
//        scrollView.backgroundColor = .red
//        scrollView.
        /*
         let appearance = UINavigationBarAppearance()
         appearance.configureWithOpaqueBackground()
         appearance.backgroundColor = .red

         navigationController?.navigationBar.standardAppearance = appearance
         navigationController?.navigationBar.compactAppearance = appearance
         navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
         navigationController?.navigationBar.scrollEdgeAppearance = appearance

         navigationController?.navigationBar.traverseSubviews(apply: { subview in
             print("New Subview")
             print(type(of: subview), "\n")
             print(subview, "\n")
             print(subview.frame, "\n")
             print(subview.backgroundColor, "\n")
             subview.backgroundColor = subview.backgroundColor?.withAlphaComponent(0.3)
         })
         */
//        navigationController?.navigationBar.

        /*
                 let headerView = UIView()
                 headerView.backgroundColor = .green //.withAlphaComponent(0.5)

                 headerView.translatesAutoresizingMaskIntoConstraints = false
         //        view.insertSubview(headerView, at: 0)
                 view.addSubview(headerView)
                 print("z nav", navigationController?.navigationBar.layer.zPosition)
                 print("z header", headerView.layer.zPosition)

                 NSLayoutConstraint.activate([
                     headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                     headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                     headerView.heightAnchor.constraint(equalToConstant: 300),
                     headerView.topAnchor.constraint(equalTo: view.topAnchor),
              //       headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
                 ])
                 */
    }

    private enum AssociatedKeys {
        nonisolated(unsafe) static var scrollCancellable: Void?
        nonisolated(unsafe) static var scrollOffset: Void?
        nonisolated(unsafe) static var headerView: Void?
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
                print("HeroKit: Scroll offset: \(offset.y)")
                /*
                 self?.navigationController?.navigationBar.traverseSubviews(apply: { subview in
                     print("New Subview")
                     print(type(of: subview), "\n")
                     print(subview, "\n")
                     print(subview.frame, "\n")
                     print(subview.backgroundColor, "\n")
                     print("Z Posistion", subview.layer.zPosition)
                    })
                  */
            }
    }

    private func findScrollView() -> UIScrollView? {
        if let tableVC = self as? UITableViewController {
            return tableVC.tableView
        }
        if let collectionVC = self as? UICollectionViewController {
            return collectionVC.collectionView
        }
        return findScrollView(in: view)
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let found = findScrollView(in: subview) {
                return found
            }
        }
        return nil
    }

}

extension UIView {
    func traverseSubviews(apply: ((UIView) -> Void)?) {
        apply?(self)
        for subview in subviews {
            subview.traverseSubviews(apply: apply)
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
