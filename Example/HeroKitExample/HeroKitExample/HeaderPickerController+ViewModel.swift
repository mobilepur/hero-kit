import Combine
import Foundation
import HeroKit
import UIKit

extension HeaderPickerController {
    class ViewModel {
        // MARK: - Published Style

        let styleSubject: CurrentValueSubject<HeroHeader.Style?, Never>

        // MARK: - Configuration State

        private let initialStyle: HeroHeader.Style?
        private var headerImage: UIImage?
        private var baseConfiguration: HeroHeader.HeaderViewConfiguration?

        /// HeaderView options
        var stretchEnabled: Bool = true {
            didSet { publishUpdatedStyle() }
        }

        var largeTitleEnabled: Bool = false {
            didSet { publishUpdatedStyle() }
        }

        var lineWrapEnabled: Bool = false {
            didSet { publishUpdatedStyle() }
        }

        var smallTitleDisplayMode: HeroHeader
            .SmallTitleDisplayMode = .system
        {
            didSet { publishUpdatedStyle() }
        }

        var inlineEnabled: Bool = false {
            didSet { publishUpdatedStyle() }
        }

        var dimmingMode: HeroHeader.InlineTitleConfiguration
            .Dimming = .none
        {
            didSet { publishUpdatedStyle() }
        }

        /// Opaque options
        private var opaqueStyle: (
            backgroundColor: UIColor,
            foregroundColor: UIColor?,
            prefersLargeTitles: Bool
        )?
        var lightModeOnlyEnabled: Bool = false {
            didSet { publishUpdatedStyle() }
        }

        // MARK: - Computed Properties

        var isHeaderViewStyle: Bool {
            baseConfiguration != nil
        }

        var isOpaqueStyle: Bool {
            opaqueStyle != nil
        }

        // MARK: - Init

        init(style: HeroHeader.Style?) {
            initialStyle = style
            styleSubject = CurrentValueSubject(style)

            extractConfiguration(from: style)
        }

        private func extractConfiguration(from style: HeroHeader.Style?) {
            switch style {
            case let .headerView(view, configuration, _):
                headerImage = (view as? UIImageView)?.image
                baseConfiguration = configuration
                stretchEnabled = configuration.stretches

                if case let .belowHeader(largeTitleConfig) = configuration.largeTitleDisplayMode {
                    largeTitleEnabled = true
                    lineWrapEnabled = largeTitleConfig.allowsLineWrap
                    smallTitleDisplayMode = largeTitleConfig.smallTitleDisplayMode
                }
                if case let .inline(inlineConfig) = configuration.largeTitleDisplayMode {
                    inlineEnabled = true
                    dimmingMode = inlineConfig.dimming
                }

            case let .opaque(_, backgroundColor, foregroundColor, prefersLargeTitles,
                             lightModeOnly):
                opaqueStyle = (backgroundColor, foregroundColor, prefersLargeTitles)
                lightModeOnlyEnabled = lightModeOnly

            case .none:
                break
            }
        }

        // MARK: - Style Generation

        private func publishUpdatedStyle() {
            guard let newStyle = buildCurrentStyle() else { return }
            styleSubject.send(newStyle)
        }

        private func buildCurrentStyle() -> HeroHeader.Style? {
            if let baseConfiguration, let headerImage {
                return buildHeaderViewStyle(
                    baseConfiguration: baseConfiguration,
                    image: headerImage
                )
            } else if let opaqueStyle {
                return buildOpaqueStyle(opaqueStyle: opaqueStyle)
            }
            return nil
        }

        private func buildHeaderViewStyle(
            baseConfiguration: HeroHeader.HeaderViewConfiguration,
            image: UIImage
        ) -> HeroHeader.Style {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            let largeTitleDisplayMode: HeroHeader.LargeTitleDisplayMode = if inlineEnabled {
                .inline(.init(dimming: dimmingMode))
            } else if largeTitleEnabled {
                .belowHeader(.init(
                    allowsLineWrap: lineWrapEnabled,
                    smallTitleDisplayMode: smallTitleDisplayMode
                ))
            } else {
                .none
            }

            let configuration = HeroHeader.HeaderViewConfiguration(
                height: baseConfiguration.height,
                minHeight: baseConfiguration.minHeight,
                stretches: stretchEnabled,
                largeTitleDisplayMode: largeTitleDisplayMode
            )

            return .headerView(
                view: imageView,
                configuration: configuration,
                title: initialStyle?.titleConfiguration
            )
        }

        private func buildOpaqueStyle(
            opaqueStyle: (
                backgroundColor: UIColor,
                foregroundColor: UIColor?,
                prefersLargeTitles: Bool
            )
        ) -> HeroHeader.Style {
            .opaque(
                title: initialStyle?.titleConfiguration ?? .init(),
                backgroundColor: opaqueStyle.backgroundColor,
                foregroundColor: opaqueStyle.foregroundColor,
                prefersLargeTitles: opaqueStyle.prefersLargeTitles,
                lightModeOnly: lightModeOnlyEnabled
            )
        }
    }
}

// MARK: - Static Data

extension HeaderPickerController.ViewModel {
    static let colorStyles: [HeroHeader.Style] = [
        // Light background, dark text
        .opaque(
            title: .init(title: "Mint"),
            backgroundColor: .systemMint,
            foregroundColor: .black,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(
                title: "Yellow",
                subtitle: "Yellow subtitle",
                largeSubtitle: "Yellow subtitle"
            ),
            backgroundColor: .systemYellow,
            foregroundColor: .black,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Cyan"),
            backgroundColor: .systemCyan,
            foregroundColor: .black,
            prefersLargeTitles: false
        ),
        // Dark background, light text
        .opaque(
            title: .init(title: "Indigo"),
            backgroundColor: .systemIndigo,
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(
                title: "Blue",
                subtitle: "Blue subtitle",
                largeSubtitle: "Blue subtitle"
            ),
            backgroundColor: .systemBlue,
            foregroundColor: .white,
            prefersLargeTitles: true
        ),
        .opaque(
            title: .init(title: "Purple"),
            backgroundColor: .systemPurple,
            foregroundColor: .white,
            prefersLargeTitles: false
        ),
    ]

    static let headerViewStyles: [HeroHeader.Style] = [
        // No large title
        .headerView(
            view: makeImageView(assetName: "bikes"),
            configuration: .init(height: 300),
            title: .init(title: "City Ride")
        ),
        // Large title below header
        .headerView(
            view: makeImageView(assetName: "temple"),
            configuration: .init(height: 300, largeTitleDisplayMode: .belowHeader()),
            title: .init(
                title: "Ancient Ruins",
                subtitle: "Lost in time",
                largeSubtitle: "Lost in time"
            )
        ),
        // Inline large title
        .headerView(
            view: makeImageView(assetName: "ricefields"),
            configuration: .init(height: 300, largeTitleDisplayMode: .inline()),
            title: .init(
                title: "Golden Fields",
                subtitle: "Bali, Indonesia",
                largeSubtitle: "Bali, Indonesia"
            )
        ),
        // Multiline large title
        .headerView(
            view: makeImageView(assetName: "vulcano"),
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
            ),
            title: .init(
                title: "The Ring of Fire",
                subtitle: "Nature's raw power",
                largeSubtitle: "Nature's raw power"
            )
        ),
        // Inline with gradient dimming
        .headerView(
            view: makeImageView(assetName: "temple"),
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .inline(.init(dimming: .gradient))
            ),
            title: .init(
                title: "Sacred Temple",
                subtitle: "Kyoto, Japan",
                largeSubtitle: "Kyoto, Japan"
            )
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

    /// Thumbnail image for collection view cell
    var cellImage: UIImage? {
        switch self {
        case let .opaque(_, backgroundColor, _, _, _):
            return Self.colorImage(for: backgroundColor)
        case let .headerView(view, _, _):
            return (view as? UIImageView)?.image
        }
    }

    /// Subtitle shown in the collection view cell (describes the style configuration)
    var cellSubtitle: String? {
        var lines: [String] = []

        switch self {
        case let .opaque(_, _, _, prefersLargeTitles, _):
            lines.append(prefersLargeTitles ? "Large Title" : "Small Title")
        case let .headerView(_, configuration, _):
            lines.append(configuration.description)
        }

        if let titleConfig = titleConfiguration, !titleConfig.description.isEmpty {
            lines.append(titleConfig.description)
        }

        return lines.isEmpty ? nil : lines.joined(separator: "\n")
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
