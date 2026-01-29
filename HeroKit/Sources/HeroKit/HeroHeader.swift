import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(backgroundColor: UIColor, foregroundColor: UIColor?)
        case headerView(view: UIView, configuration: HeaderViewConfiguration = .init())
    }

    public struct HeaderViewConfiguration {
        let height: CGFloat
        let minHeight: CGFloat?
        let bounces: Bool

        public init(height: CGFloat = 240, minHeight: CGFloat? = nil, bounces: Bool = true) {
            self.height = height
            self.minHeight = minHeight
            self.bounces = bounces
        }
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
