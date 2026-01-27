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

    private func setupHeader(style _: HeroHeader.Style, scrollView _: UIScrollView) {
        let headerView = UIView()
        headerView.backgroundColor = .green

        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
        ])
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
