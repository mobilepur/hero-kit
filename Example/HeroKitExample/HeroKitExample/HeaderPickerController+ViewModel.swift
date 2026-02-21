import HeroKit
import UIKit

// MARK: - HeaderContent

enum HeaderContent {
    case color(
        title: String,
        subtitle: String? = nil,
        backgroundColor: UIColor,
        foregroundColor: UIColor? = nil
    )
    case localImage(
        title: String,
        subtitle: String? = nil,
        assetName: String,
        height: CGFloat = 300
    )
    case remoteImage(
        title: String,
        subtitle: String? = nil,
        url: URL,
        height: CGFloat = 300
    )
}

// MARK: - Display Helpers

extension HeaderContent {

    var displayName: String {
        switch self {
        case let .color(title, _, _, _): title
        case let .localImage(title, _, _, _): title
        case let .remoteImage(title, _, _, _): title
        }
    }

    var cellSubtitle: String? {
        switch self {
        case let .color(_, subtitle, _, _): subtitle
        case let .localImage(_, subtitle, _, _): subtitle
        case let .remoteImage(_, subtitle, _, _): subtitle
        }
    }

    var cellImage: UIImage? {
        switch self {
        case let .color(_, _, backgroundColor, _):
            return Self.colorSwatch(for: backgroundColor)
        case let .localImage(_, _, assetName, _):
            return UIImage(named: assetName)
        case .remoteImage:
            return UIImage(systemName: "photo")
        }
    }

    var isVisualHeader: Bool {
        switch self {
        case .color: false
        case .localImage, .remoteImage: true
        }
    }

    private static func colorSwatch(
        for color: UIColor,
        size: CGSize = CGSize(width: 28, height: 28)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Static Data

extension HeaderContent {

    static let colorItems: [HeaderContent] = [
        .color(title: "Mint", backgroundColor: .systemMint, foregroundColor: .black),
        .color(
            title: "Blue",
            subtitle: "Blue subtitle",
            backgroundColor: .systemBlue,
            foregroundColor: .white
        ),
        .color(title: "Purple", backgroundColor: .systemPurple, foregroundColor: .white),
    ]

    static let localImageItems: [HeaderContent] = [
        .localImage(title: "City Ride", assetName: "bikes"),
        .localImage(title: "Ancient Ruins", subtitle: "Lost in time", assetName: "temple"),
        .localImage(title: "Golden Fields", subtitle: "Bali, Indonesia", assetName: "ricefields"),
    ]

    static let transitionItems: [HeaderContent] = [
        .localImage(title: "City Ride", assetName: "bikes"),
        .localImage(title: "Ancient Ruins", subtitle: "Lost in time", assetName: "temple"),
        .localImage(title: "Golden Fields", subtitle: "Bali, Indonesia", assetName: "ricefields"),
    ]

    static let remoteImageItems: [HeaderContent] = [
        .remoteImage(
            title: "Remote Landscape",
            url: URL(string: "https://picsum.photos/id/10/800/600")!
        ),
        .remoteImage(
            title: "Mountain View",
            subtitle: "From the web",
            url: URL(string: "https://picsum.photos/id/29/800/600")!
        ),
        .remoteImage(
            title: "Desert Road",
            subtitle: "Endless horizon",
            url: URL(string: "https://picsum.photos/id/65/800/600")!
        ),
    ]
}

// MARK: - ContentMode helpers

extension UIView.ContentMode {
    var displayName: String {
        switch self {
        case .scaleAspectFill: "Aspect Fill"
        case .scaleAspectFit: "Aspect Fit"
        case .scaleToFill: "Scale to Fill"
        default: "Other"
        }
    }
}

// MARK: - LargeTitleDisplayMode helpers

extension HeroHeader.LargeTitleDisplayMode {
    var displayName: String {
        switch self {
        case .none: "None"
        case .belowHeader: "Below Header"
        case .inline: "Inline"
        }
    }
}

// MARK: - SmallTitleDisplayMode helpers

extension HeroHeader.SmallTitleDisplayMode {
    static var allCases: [HeroHeader.SmallTitleDisplayMode] {
        [.never, .system, .always]
    }

    var displayName: String {
        switch self {
        case .never: "Never"
        case .system: "System"
        case .always: "Always"
        }
    }
}

// MARK: - Dimming helpers

extension HeroHeader.InlineTitleConfiguration.Dimming {
    static var allCases: [HeroHeader.InlineTitleConfiguration.Dimming] {
        [.none, .complete, .gradient]
    }

    var displayName: String {
        switch self {
        case .none: "None"
        case .complete: "Complete"
        case .gradient: "Gradient"
        }
    }
}
