import Foundation
import HeroKit
import UIKit

extension HeaderPickerController {
    class ViewModel {
        let style: HeroHeader.Style

        init(style: HeroHeader.Style) {
            self.style = style
        }
    }
}

// MARK: - Static Data

extension HeaderPickerController.ViewModel {
    /// Asset names for headerView styles (keyed by title)
    static let assetNames: [String: String] = [
        "Bikes": "bikes",
        "Explore": "temple",
        "Bikes & Beyond": "bikes",
        "Ancient Temples of Bali": "vulcano",
    ]

    static let colorStyles: [HeroHeader.Style] = [
        .opaque(
            title: .init(title: "Red", subtitle: "A warm color"),
            backgroundColor: UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Orange"),
            backgroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),
            foregroundColor: .white
        ),
        .opaque(
            title: .init(title: "Green"),
            backgroundColor: UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0),
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Teal"),
            backgroundColor: UIColor(red: 0.19, green: 0.69, blue: 0.78, alpha: 1.0),
            foregroundColor: .white
        ),
        .opaque(
            title: .init(title: "Blue", subtitle: "Like the sky"),
            backgroundColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Indigo"),
            backgroundColor: UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1.0),
            foregroundColor: .white
        ),
        .opaque(
            title: .init(title: "Purple"),
            backgroundColor: UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0),
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Pink"),
            backgroundColor: UIColor(red: 1.0, green: 0.18, blue: 0.33, alpha: 1.0),
            foregroundColor: .white
        ),
    ]

    static let headerViewStyles: [HeroHeader.Style] = [
        // No large title
        .headerView(
            view: makeImageView(assetName: "bikes"),
            configuration: .init(height: 300),
            title: .init(title: "Bikes")
        ),
        // Single line large title
        .headerView(
            view: makeImageView(assetName: "temple"),
            configuration: .init(height: 300, largeTitleDisplayMode: .belowHeader()),
            title: .init(title: "Explore")
        ),
        // Inline large title
        .headerView(
            view: makeImageView(assetName: "bikes"),
            configuration: .init(height: 300, largeTitleDisplayMode: .inline()),
            title: .init(title: "Bikes & Beyond")
        ),
        // Two line large title
        .headerView(
            view: makeImageView(assetName: "vulcano"),
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
            ),
            title: .init(title: "Ancient Temples of Bali")
        ),
    ]

    private static func makeImageView(assetName: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: assetName))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
}

// MARK: - HeroHeader.Style Display Helpers

extension HeroHeader.Style {
    /// Display name for collection view cell
    var displayName: String {
        titleConfiguration?.title ?? "Untitled"
    }

    /// Asset name for headerView styles (used for delegate callback)
    var assetName: String? {
        guard let title = titleConfiguration?.title else { return nil }
        return HeaderPickerController.ViewModel.assetNames[title]
    }

    /// Thumbnail image for collection view cell
    var cellImage: UIImage? {
        switch self {
        case let .opaque(_, backgroundColor, _, _, _):
            return Self.colorImage(for: backgroundColor)
        case .headerView:
            guard let assetName else { return nil }
            return UIImage(named: assetName)
        }
    }

    /// Subtitle shown in the collection view cell (describes the style configuration)
    var cellSubtitle: String? {
        switch self {
        case let .opaque(_, _, _, prefersLargeTitles, _):
            return prefersLargeTitles ? "Large Title" : nil
        case let .headerView(_, configuration, _):
            return configuration.description
        }
    }

    private static func colorImage(
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
