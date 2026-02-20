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
            image: ImageConfiguration,
            configuration: HeaderViewConfiguration = .init(),
            title: TitleConfiguration? = nil
        )

        public var titleConfiguration: TitleConfiguration? {
            switch self {
            case let .opaque(title, _, _, _, _):
                return title
            case let .headerView(_, _, title):
                return title
            case let .image(_, _, title):
                return title
            }
        }

        public var headerViewConfiguration: HeaderViewConfiguration? {
            switch self {
            case .opaque:
                return nil
            case let .headerView(_, configuration, _):
                return configuration
            case let .image(_, configuration, _):
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
            case let .image(_, _, titleConfiguration):
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
            case let .image(_, _, titleConfiguration):
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

    public struct Accessory {
        public let type: AccessoryType
        public let position: Position

        public init(_ type: AccessoryType, position: Position = .trailing) {
            self.type = type
            self.position = position
        }

        public enum Position {
            case leading
            case trailing
        }

        public enum AccessoryType {
            case view(UIView)
            case button(configuration: UIButton.Configuration, action: UIAction)
        }
    }

    public enum LargeTitleDisplayMode {
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

    public struct InlineTitleConfiguration {
        public let dimming: Dimming
        public let minimumScaleFactor: CGFloat?
        public let insets: TitleInsets
        public let accessories: [Accessory]

        public init(
            dimming: Dimming = .none,
            minimumScaleFactor: CGFloat? = nil,
            insets: TitleInsets = .init(),
            accessories: [Accessory] = []
        ) {
            self.dimming = dimming
            self.minimumScaleFactor = minimumScaleFactor
            self.insets = insets
            self.accessories = accessories
        }

        public enum Dimming: Hashable, Sendable {
            case none
            case complete
            case gradient
        }
    }

    public struct LargeTitleConfiguration {
        public let allowsLineWrap: Bool
        public let minimumScaleFactor: CGFloat?
        public let smallTitleDisplayMode: SmallTitleDisplayMode
        public let insets: TitleInsets
        public let accessories: [Accessory]

        public init(
            allowsLineWrap: Bool = false,
            minimumScaleFactor: CGFloat? = nil,
            smallTitleDisplayMode: SmallTitleDisplayMode = .system,
            insets: TitleInsets = .init(),
            accessories: [Accessory] = []
        ) {
            self.allowsLineWrap = allowsLineWrap
            self.minimumScaleFactor = minimumScaleFactor
            self.smallTitleDisplayMode = smallTitleDisplayMode
            self.insets = insets
            self.accessories = accessories
        }
    }

    public enum SmallTitleDisplayMode: Hashable, Sendable {
        case never
        case system // default behaviour: small title only displayed when large titles are not
        /// visible
        case always
    }

    public struct ImageConfiguration {
        public let url: URL
        public let contentMode: UIView.ContentMode
        public let backgroundColor: UIColor?
        public let loadingType: LoadingType

        public init(
            url: URL,
            contentMode: UIView.ContentMode = .scaleAspectFill,
            backgroundColor: UIColor? = nil,
            loadingType: LoadingType = .spinner
        ) {
            self.url = url
            self.contentMode = contentMode
            self.backgroundColor = backgroundColor
            self.loadingType = loadingType
        }
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
