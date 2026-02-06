import UIKit

// MARK: - General Helpers

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

// MARK: - Navigation Bar Appearance (delegate to UINavigationController)

extension UIViewController {

    /// Applies a single appearance to all navigation bar appearance properties
    func applyNavigationBarAppearance(_ appearance: UINavigationBarAppearance) {
        navigationController?.applyAppearance(appearance)
    }

    /// Configures navigation bar with transparent background
    func configureTransparentNavigationBar() {
        navigationController?.configureTransparentAppearance()
    }

    /// Configures navigation bar with default system background
    func configureDefaultNavigationBar() {
        navigationController?.configureDefaultAppearance()
    }

    /// Configures navigation bar with opaque colored background
    func configureOpaqueNavigationBar(backgroundColor: UIColor, foregroundColor: UIColor?) {
        navigationController?.configureOpaqueAppearance(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
    }

    /// Sets the title text color on all navigation bar appearances
    func setNavigationBarTitleColor(_ color: UIColor) {
        navigationController?.setTitleColor(color)
    }
}

// MARK: - UIView Helpers

extension UIView {

    func traverseSubviews(apply: ((UIView) -> Void)?) {
        apply?(self)
        for subview in subviews {
            subview.traverseSubviews(apply: apply)
        }
    }

}
