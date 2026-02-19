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
            configuration: HeaderViewConfiguration = .init(),
            title: TitleConfiguration? = nil
        )

        case image(
            url: URL,
            contentMode: UIView.ContentMode = .scaleAspectFill,
            backgroundColor: UIColor? = nil,
            loadingType: LoadingType = .spinner,
            configuration: HeaderViewConfiguration = .init(),
            title: TitleConfiguration? = nil
        )

        public var titleConfiguration: TitleConfiguration? {
            switch self {
            case let .opaque(title, _, _, _, _):
                return title
            case let .headerView(_, _, title):
                return title
            case let .image(_, _, _, _, _, title):
                return title
            }
        }

        public var headerViewConfiguration: HeaderViewConfiguration? {
            switch self {
            case .opaque:
                return nil
            case let .headerView(_, configuration, _):
                return configuration
            case let .image(_, _, _, _, configuration, _):
                return configuration
            }
        }

        public var largeTitle: String? {
            switch self {
            case let .opaque(
                title: titleConfiguration,
                backgroundColor: _,
                foregroundColor: _,
                prefersLargeTitles: prefersLargeTitle,
                lightModeOnly: _
            ):
                if let largeTitle = titleConfiguration.largeTitle {
                    return largeTitle
                }
                if prefersLargeTitle {
                    return titleConfiguration.title
                }
                return nil
            case let .headerView(_, _, titleConfiguration):
                return titleConfiguration?.largeTitle ?? titleConfiguration?.title
            case let .image(_, _, _, _, _, titleConfiguration):
                return titleConfiguration?.largeTitle ?? titleConfiguration?.title
            }
        }

        public var largeSubtitle: String? {
            // only allow subtitles if large title is set
            guard largeTitle != nil else { return nil }
            switch self {
            case let .opaque(
                title: titleConfiguration,
                backgroundColor: _,
                foregroundColor: _,
                prefersLargeTitles: prefersLargeTitle,
                lightModeOnly: _
            ):
                if let largeSubtitle = titleConfiguration.largeSubtitle {
                    return largeSubtitle
                }
                if prefersLargeTitle {
                    return titleConfiguration.subtitle
                }
                return nil
            case let .headerView(_, _, titleConfiguration):
                return titleConfiguration?.largeSubtitle ?? titleConfiguration?.subtitle
            case let .image(_, _, _, _, _, titleConfiguration):
                return titleConfiguration?.largeSubtitle ?? titleConfiguration?.subtitle
            }
        }

        public var foregroundColor: UIColor? {
            switch self {
            case let .opaque(_, _, foregroundColor, _, _):
                return foregroundColor
            case .headerView, .image:
                return nil
            }
        }
    }

    // MARK: - configurations

    public struct TitleConfiguration: Hashable, Sendable {
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
            height: CGFloat = 200,
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

    public struct TitleInsets: Hashable, Sendable {
        public let top: CGFloat?
        public let leading: CGFloat?
        public let bottom: CGFloat?
        public let trailing: CGFloat?

        public init(
            top: CGFloat? = nil,
            leading: CGFloat? = nil,
            bottom: CGFloat? = nil,
            trailing: CGFloat? = nil
        ) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }

        /// Sets all insets to the same value.
        public static func all(_ value: CGFloat) -> TitleInsets {
            TitleInsets(top: value, leading: value, bottom: value, trailing: value)
        }

        /// Sets leading and trailing to the same value.
        public static func horizontal(_ value: CGFloat) -> TitleInsets {
            TitleInsets(leading: value, trailing: value)
        }
    }

    public struct InlineTitleConfiguration: Hashable, Sendable {
        public let dimming: Dimming
        public let insets: TitleInsets

        public init(dimming: Dimming = .none, insets: TitleInsets = .init()) {
            self.dimming = dimming
            self.insets = insets
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
        public let insets: TitleInsets

        public init(
            allowsLineWrap: Bool = false,
            smallTitleDisplayMode: SmallTitleDisplayMode = .system,
            insets: TitleInsets = .init()
        ) {
            self.allowsLineWrap = allowsLineWrap
            self.smallTitleDisplayMode = smallTitleDisplayMode
            self.insets = insets
        }
    }

    public enum SmallTitleDisplayMode: Hashable, Sendable {
        case never
        case system // default behaviour: small title only displayed when large titles are not
        /// visible
        case always
    }

    public enum LoadingType: Hashable, Sendable {
        case spinner
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
        case titleNotFound
    }
}
