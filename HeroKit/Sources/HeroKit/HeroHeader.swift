import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case opaque(
            title: TitleConfiguration,
            backgroundColor: UIColor,
            foregroundColor: UIColor? = nil,
            prefersLargeTitles: Bool = false,
            lightModeOnly: Bool = false
        )
        case headerView(
            view: UIView,
            configuration: HeaderViewConfiguration = .init()
        )
    }

    // MARK: - configurations

    public struct TitleConfiguration {
        public let title: String?
        public let subtitle: String?
        public let largeTitle: String?
        public let largeSubtitle: String?

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            largeTitle: String? = nil,
            largeSubtitle: String? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.largeTitle = largeTitle
            self.largeSubtitle = largeSubtitle
        }
    }

    public struct HeaderViewConfiguration {
        public let height: CGFloat
        public let stretches: Bool
        public let largeTitleDisplayMode: LargeTitleDisplayMode
        public let minHeight: CGFloat?

        public init(
            height: CGFloat = 1000,
            minHeight: CGFloat? = nil,
            stretches: Bool = true,
            largeTitleDisplayMode: LargeTitleDisplayMode = .none
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
        case inline(InlineTitleConfiguration = .init())
    }

    public struct InlineTitleConfiguration: Hashable, Sendable {
        public let dimming: Dimming

        public init(dimming: Dimming = .none) {
            self.dimming = dimming
        }

        public enum Dimming: Hashable, Sendable {
            case none
            case complete
            case gradient
        }
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
        case system // default behaviour: small title only displayed when large titles are not
        // visible
        case always
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
        case titleNotFound
    }
}
