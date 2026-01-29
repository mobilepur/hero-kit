import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(backgroundColor: UIColor, foregroundColor: UIColor?)
        case headerView(view: UIView, height: CGFloat, minHeight: CGFloat? = nil)
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
