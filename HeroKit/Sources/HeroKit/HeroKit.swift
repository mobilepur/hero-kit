import Combine
import UIKit

// MARK: - Header Style

public enum HeroHeaderStyle {
    case color(UIColor)
    //  case image(UIImage, height: CGFloat = 200)
}

// MARK: - UIViewController Extension

public extension UIViewController {

    func configureHeader(_ style: HeroHeaderStyle, scrollView: UIScrollView? = nil) {
        guard let targetScrollView = scrollView ?? findScrollView() else {
            print("HeroKit: No scroll view found")
            return
        }

        // TODO: Implement header configuration
        print("HeroKit: Configuring header with style: \(style)")
        print("HeroKit: Found scroll view: \(targetScrollView)")
    }

    private func findScrollView() -> UIScrollView? {
        // Check known ViewController types first
        if let tableVC = self as? UITableViewController {
            return tableVC.tableView
        }
        if let collectionVC = self as? UICollectionViewController {
            return collectionVC.collectionView
        }

        // Search view hierarchy
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
