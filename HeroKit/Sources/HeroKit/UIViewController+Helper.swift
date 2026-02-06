import UIKit

extension UIViewController {

    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    func findScrollView() -> UIScrollView? {
        if let tableVC = self as? UITableViewController {
            return tableVC.tableView
        }
        if let collectionVC = self as? UICollectionViewController {
            return collectionVC.collectionView
        }
        return findScrollView(in: view)
    }

    func findScrollView(in view: UIView) -> UIScrollView? {
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
