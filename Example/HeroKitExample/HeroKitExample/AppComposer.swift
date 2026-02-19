import HeroKit
import UIKit

class AppComposer {

    private let window: UIWindow
    private let model = Model()
    private weak var navigationController: UINavigationController?

    init(window: UIWindow) {
        self.window = window
    }

    private let launcherContent: HeaderContent = .color(
        title: "Launcher",
        backgroundColor: .red,
        foregroundColor: .white
    )

    func start() {
        let pickerController = HeaderPickerController(
            title: "Style Picker",
            navbarStyle: buildStyle(from: launcherContent)
        )
        pickerController.content = launcherContent
        pickerController.delegate = self

        let nav = UINavigationController(rootViewController: pickerController)
        navigationController = nav

        window.rootViewController = nav
        window.makeKeyAndVisible()
    }

    private func presentSettings(from presenter: UIViewController) {
        let settingsController = SettingsController(settings: model.settings)
        settingsController.delegate = self
        let nav = UINavigationController(rootViewController: settingsController)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        presenter.present(nav, animated: true)
    }
}

// MARK: - Style Building

extension AppComposer {

    private func buildStyle(from content: HeaderContent) -> HeroHeader.Style {
        let settings = model.settings
        switch content {
        case let .color(title, subtitle, backgroundColor, foregroundColor):
            let titleConfig = makeTitleConfig(title: title, subtitle: subtitle)
            return .opaque(
                title: applyTitleLength(to: titleConfig),
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: settings.largeTitle,
                lightModeOnly: settings.lightModeOnly
            )

        case let .localImage(title, subtitle, assetName, height):
            let imageView = UIImageView(image: UIImage(named: assetName))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            let titleConfig = makeTitleConfig(title: title, subtitle: subtitle)
            let configuration = makeHeaderViewConfiguration(height: height)
            return .headerView(
                view: imageView,
                configuration: configuration,
                title: applyTitleLength(to: titleConfig)
            )

        case let .remoteImage(title, subtitle, url, height):
            let titleConfig = makeTitleConfig(title: title, subtitle: subtitle)
            let configuration = makeHeaderViewConfiguration(height: height)
            return .image(
                url: url,
                contentMode: settings.imageContentMode.contentMode,
                backgroundColor: settings.imageBackgroundColor.color,
                configuration: configuration,
                title: applyTitleLength(to: titleConfig)
            )
        }
    }

    private func makeTitleConfig(
        title: String,
        subtitle: String?
    ) -> HeroHeader.TitleConfiguration {
        .init(title: title, subtitle: subtitle, largeSubtitle: subtitle)
    }

    private func makeHeaderViewConfiguration(
        height: CGFloat
    ) -> HeroHeader.HeaderViewConfiguration {
        let settings = model.settings
        let accessories = settings.accessoryMode.accessories

        let largeTitleDisplayMode: HeroHeader.LargeTitleDisplayMode =
            if settings.inline {
                .inline(.init(
                    dimming: settings.dimming,
                    accessories: accessories
                ))
            } else if settings.largeTitle {
                .belowHeader(.init(
                    allowsLineWrap: settings.lineWrap,
                    smallTitleDisplayMode: settings.smallTitleDisplayMode,
                    accessories: accessories
                ))
            } else {
                .none
            }

        return HeroHeader.HeaderViewConfiguration(
            height: height,
            stretches: settings.stretch,
            largeTitleDisplayMode: largeTitleDisplayMode
        )
    }

    private func applyTitleLength(
        to title: HeroHeader.TitleConfiguration
    ) -> HeroHeader.TitleConfiguration {
        guard model.settings.titleLength == .long else { return title }
        return .init(
            title: title.title.map { "\($0) – An Unforgettable Journey" },
            subtitle: title.subtitle,
            largeTitle: title.largeTitle.map { "\($0) – An Unforgettable Journey" },
            largeSubtitle: title.largeSubtitle
        )
    }
}

// MARK: - HeaderPickerControllerDelegate

extension AppComposer: HeaderPickerControllerDelegate {

    func headerPicker(
        _ controller: HeaderPickerController,
        didSelect content: HeaderContent
    ) {
        let resolvedStyle = buildStyle(from: content)
        let nextController = HeaderPickerController(
            title: content.displayName,
            navbarStyle: resolvedStyle
        )
        nextController.content = content
        nextController.delegate = self
        controller.navigationController?.pushViewController(nextController, animated: true)
    }

    func headerPicker(_ controller: HeaderPickerController, showSettings _: Void) {
        presentSettings(from: controller)
    }
}

// MARK: - SettingsControllerDelegate

extension AppComposer: SettingsControllerDelegate {
    func settingsControllerDidUpdate(_ controller: SettingsController) {
        model.settings = controller.settings
        updateVisibleController()
    }

    private func updateVisibleController() {
        guard let topController = navigationController?
            .topViewController as? HeaderPickerController,
            let content = topController.content
        else { return }
        let resolvedStyle = buildStyle(from: content)
        try? topController.setHeader(resolvedStyle)
    }
}

// MARK: - Model

extension AppComposer {
    class Model {
        var settings = AppSettings()
    }

    struct AppSettings {
        var lightModeOnly: Bool = false
        var stretch: Bool = true
        var largeTitle: Bool = true
        var lineWrap: Bool = false
        var smallTitleDisplayMode: HeroHeader.SmallTitleDisplayMode = .system
        var inline: Bool = false
        var dimming: HeroHeader.InlineTitleConfiguration.Dimming = .none
        var titleLength: TitleLength = .normal
        var accessoryMode: AccessoryMode = .none
        var imageContentMode: ImageContentMode = .aspectFill
        var imageBackgroundColor: ImageBackgroundColor = .none
    }

    enum TitleLength: Hashable, Sendable, CaseIterable {
        case normal
        case long

        var displayName: String {
            switch self {
            case .normal: "Normal"
            case .long: "Long"
            }
        }
    }

    enum ImageContentMode: Hashable, Sendable, CaseIterable {
        case aspectFill
        case aspectFit
        case scaleToFill

        var displayName: String {
            switch self {
            case .aspectFill: "Aspect Fill"
            case .aspectFit: "Aspect Fit"
            case .scaleToFill: "Scale to Fill"
            }
        }

        var contentMode: UIView.ContentMode {
            switch self {
            case .aspectFill: .scaleAspectFill
            case .aspectFit: .scaleAspectFit
            case .scaleToFill: .scaleToFill
            }
        }
    }

    enum AccessoryMode: Hashable, Sendable, CaseIterable {
        case none
        case favorite

        var displayName: String {
            switch self {
            case .none: "None"
            case .favorite: "Favorite"
            }
        }

        var accessories: [HeroHeader.Accessory] {
            switch self {
            case .none: return []
            case .favorite:
                var config = UIButton.Configuration.plain()
                config.image = UIImage(systemName: "heart")
                config.baseForegroundColor = .label
                return [.init(.button(configuration: config, action: UIAction { _ in }))]
            }
        }
    }

    enum ImageBackgroundColor: Hashable, Sendable, CaseIterable {
        case none
        case systemBackground
        case secondarySystemBackground
        case black
        case white

        var displayName: String {
            switch self {
            case .none: "None"
            case .systemBackground: "System Background"
            case .secondarySystemBackground: "Secondary"
            case .black: "Black"
            case .white: "White"
            }
        }

        var color: UIColor? {
            switch self {
            case .none: nil
            case .systemBackground: .systemBackground
            case .secondarySystemBackground: .secondarySystemBackground
            case .black: .black
            case .white: .white
            }
        }
    }
}
