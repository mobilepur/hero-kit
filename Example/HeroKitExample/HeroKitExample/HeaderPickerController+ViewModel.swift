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

        private var inlineInsets: HeroHeader.TitleInsets = .init()
        private var belowHeaderInsets: HeroHeader.TitleInsets = .init()
        private var accessories: [HeroHeader.Accessory] = []

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
                    belowHeaderInsets = largeTitleConfig.insets
                    accessories = largeTitleConfig.accessories
                    largeTitleEnabled = true
                    lineWrapEnabled = largeTitleConfig.allowsLineWrap
                    smallTitleDisplayMode = largeTitleConfig.smallTitleDisplayMode
                }
                if case let .inline(inlineConfig) = configuration.largeTitleDisplayMode {
                    inlineInsets = inlineConfig.insets
                    accessories = inlineConfig.accessories
                    inlineEnabled = true
                    dimmingMode = inlineConfig.dimming
                }

            case let .opaque(_, backgroundColor, foregroundColor, prefersLargeTitles,
                             lightModeOnly):
                opaqueStyle = (backgroundColor, foregroundColor, prefersLargeTitles)
                lightModeOnlyEnabled = lightModeOnly

            case let .image(_, _, _, _, configuration, _):
                baseConfiguration = configuration

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
                .inline(.init(dimming: dimmingMode, insets: inlineInsets, accessories: accessories))
            } else if largeTitleEnabled {
                .belowHeader(.init(
                    allowsLineWrap: lineWrapEnabled,
                    smallTitleDisplayMode: smallTitleDisplayMode,
                    insets: belowHeaderInsets,
                    accessories: accessories
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
        .opaque(
            title: .init(title: "Mint"),
            backgroundColor: .systemMint,
            foregroundColor: .black,
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
        .headerView(
            view: makeImageView(assetName: "bikes"),
            configuration: .init(height: 300),
            title: .init(title: "City Ride")
        ),
        .headerView(
            view: makeImageView(assetName: "temple"),
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .belowHeader(.init(
                    accessories: [
                        .init(.button(
                            configuration: .plain().withHeartImage(),
                            action: UIAction { _ in }
                        )),
                    ]
                ))
            ),
            title: .init(
                title: "Ancient Ruins",
                subtitle: "Lost in time",
                largeSubtitle: "Lost in time"
            )
        ),
        .headerView(
            view: makeImageView(assetName: "ricefields"),
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .inline(.init(
                    dimming: .gradient,
                    accessories: [
                        .init(.button(
                            configuration: .plain().withBookmarkImage(tintColor: .white),
                            action: UIAction { _ in }
                        )),
                    ]
                ))
            ),
            title: .init(
                title: "Golden Fields",
                subtitle: "Bali, Indonesia",
                largeSubtitle: "Bali, Indonesia"
            )
        ),
    ]

    static let imageStyles: [HeroHeader.Style] = [
        .image(
            url: URL(string: "https://picsum.photos/id/10/800/600")!,
            contentMode: .scaleAspectFill,
            configuration: .init(height: 300),
            title: .init(title: "Remote Landscape")
        ),
        .image(
            url: URL(string: "https://picsum.photos/id/29/800/600")!,
            contentMode: .scaleAspectFit,
            backgroundColor: .secondarySystemBackground,
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .belowHeader()
            ),
            title: .init(
                title: "Mountain View",
                subtitle: "From the web",
                largeSubtitle: "From the web"
            )
        ),
        .image(
            url: URL(string: "https://picsum.photos/id/65/800/600")!,
            contentMode: .scaleAspectFill,
            configuration: .init(
                height: 300,
                largeTitleDisplayMode: .inline(.init(dimming: .gradient))
            ),
            title: .init(
                title: "Desert Road",
                subtitle: "Endless horizon",
                largeSubtitle: "Endless horizon"
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

// MARK: - Button Configuration Helpers

private extension UIButton.Configuration {
    func withHeartImage() -> UIButton.Configuration {
        var config = self
        config.image = UIImage(systemName: "heart")
        config.baseForegroundColor = .label
        return config
    }

    func withBookmarkImage(tintColor: UIColor) -> UIButton.Configuration {
        var config = self
        config.image = UIImage(systemName: "bookmark")
        config.baseForegroundColor = tintColor
        return config
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
        case .image:
            return UIImage(systemName: "photo")
        }
    }

    /// Subtitle shown in the collection view cell
    var cellSubtitle: String? {
        switch self {
        case .opaque:
            return nil
        case let .headerView(_, configuration, _):
            return configuration.largeTitleDisplayMode.displayName
        case let .image(_, contentMode, backgroundColor, _, configuration, _):
            var lines = [contentMode.displayName]
            if backgroundColor != nil {
                lines.append("Custom Background")
            }
            lines.append(configuration.largeTitleDisplayMode.displayName)
            return lines.joined(separator: ", ")
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
