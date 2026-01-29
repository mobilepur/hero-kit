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
        public let stretches: Bool

        public init(height: CGFloat = 1000, minHeight: CGFloat? = nil, stretches: Bool = true) {
            self.height = height
            self.minHeight = minHeight
            self.stretches = stretches
        }
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
