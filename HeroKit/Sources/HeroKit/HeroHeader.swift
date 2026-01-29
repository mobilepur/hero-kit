import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(backgroundColor: UIColor, foregroundColor: UIColor?)
        case headerView(view: UIView, configuration: HeaderViewConfiguration = .init())
    }

    public struct HeaderViewConfiguration {
        public let height: CGFloat
        public let minHeight: CGFloat?
        public let bounces: Bool

        public init(height: CGFloat = 1000, minHeight: CGFloat? = nil, bounces: Bool = true) {
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
