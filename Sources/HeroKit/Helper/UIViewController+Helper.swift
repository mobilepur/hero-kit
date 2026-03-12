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

    /// Walks up the parent chain to find the root parent that is the
    /// topViewController of the navigation stack.
    func findRootParent() -> UIViewController {
        var current: UIViewController = self
        while let parent = current.parent,
              !(parent is UINavigationController)
        {
            current = parent
        }
        return current
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

public extension UIViewController {

    /// Configures navigation bar with transparent background
    func configureTransparentNavigationBar() {
        navigationController?.configureTransparentAppearance()
    }

    /// Configures navigation bar with default system background
    func configureDefaultNavigationBar() {
        navigationController?.configureDefaultAppearance()
    }

    /// Configures navigation bar with opaque colored background
    func configureOpaqueNavigationBar(
        title: String? = nil,
        backgroundColor: UIColor,
        foregroundColor: UIColor?
    ) {
        if let title {
            self.title = title
        }
        navigationController?.configureOpaqueAppearance(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
    }

    func setNavigationBarTintColor(_ color: UIColor) {
        setNavigationBarTitleColor(color)
        setNavigationBarSubtitleColor(color.withAlphaComponent(0.7))
    }

    /// Sets the title text color on all navigation bar appearances
    func setNavigationBarTitleColor(_ color: UIColor) {
        navigationController?.setTitleColor(color)
    }

    /// Sets the subtitle text color on all navigation bar appearances (iOS 26+)
    func setNavigationBarSubtitleColor(_ color: UIColor) {
        if #available(iOS 26, *) {
            navigationController?.setSubtitleColor(color)
        }
    }
}
