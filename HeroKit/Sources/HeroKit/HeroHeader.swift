import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(
            backgroundColor: UIColor,
            foregroundColor: UIColor? = nil,
            prefersLargeTitles: Bool = false
        )
        case headerView(view: UIView, configuration: HeaderViewConfiguration = .init())
    }

    // MARK: - configurations

    public struct HeaderViewConfiguration {
        public let height: CGFloat
        public let stretches: Bool
        public let largeTitleDisplayMode: LargeTitleDisplayMode
        public let minHeight: CGFloat?

        public init(
            height: CGFloat = 1000,
            minHeight: CGFloat? = nil,
            stretches: Bool = true,
            largeTitleDisplayMode: LargeTitleDisplayMode = .none,
        ) {
            self.height = height
            self.minHeight = minHeight
            self.stretches = stretches
            self.largeTitleDisplayMode = largeTitleDisplayMode
        }
    }

    public enum LargeTitleDisplayMode: Hashable, Sendable {
        case none
        case belowHeader(LargeTitleConfiguration = .init())
    }

    public struct LargeTitleConfiguration: Hashable, Sendable {
        public let allowsLineWrap: Bool
        public let smallTitleDisplayMode: SmallTitleDisplayMode

        public init(
            allowsLineWrap: Bool = false,
            smallTitleDisplayMode: SmallTitleDisplayMode = .system
        ) {
            self.allowsLineWrap = allowsLineWrap
            self.smallTitleDisplayMode = smallTitleDisplayMode
        }
    }

    public enum SmallTitleDisplayMode: Hashable, Sendable {
        case never
        case system // default behaviour: small title only displayed when large titles are not visible
        case always
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
