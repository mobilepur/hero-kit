import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(backgroundColor: UIColor, foregroundColor: UIColor?)
        case headerView(view: UIView, configuration: HeaderViewConfiguration = .init())
    }

    // MARK: - configurations

    public struct HeaderViewConfiguration {
        public let height: CGFloat
        public let minHeight: CGFloat?
        public let stretches: Bool
        public let largeTitleDisplayMode: LargeTitleDisplayMode
        public let smallTitleDisplayMode: SmallTitleDisplayMode

        public init(
            height: CGFloat = 1000,
            minHeight: CGFloat? = nil,
            stretches: Bool = true,
            largeTitleDisplayMode: LargeTitleDisplayMode = .none,
            smallTitleDisplayMode: SmallTitleDisplayMode = .whenLargeTitleHidden
        ) {
            self.height = height
            self.minHeight = minHeight
            self.stretches = stretches
            self.largeTitleDisplayMode = largeTitleDisplayMode
            self.smallTitleDisplayMode = smallTitleDisplayMode
        }
    }

    public enum SmallTitleDisplayMode: Hashable, Sendable {
        case never
        case always
        case whenHeaderCollapsed
        case whenLargeTitleHidden
    }

    public enum LargeTitleDisplayMode: Hashable, Sendable {
        case none
        case belowHeader(LargeTitleConfiguration = .init())
    }

    public struct LargeTitleConfiguration: Hashable, Sendable {
        public let allowsLineWrap: Bool

        public init(allowsLineWrap: Bool = false) {
            self.allowsLineWrap = allowsLineWrap
        }
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
