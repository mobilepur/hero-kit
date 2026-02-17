import HeroKit
import UIKit

class AppComposer {

    private let window: UIWindow
    private let model = Model()
    private weak var navigationController: UINavigationController?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let pickerController = HeaderPickerController(
            title: "Style Picker",
            navbarStyle: .opaque(
                title: .init(title: "Launcher"),
                backgroundColor: .red,
                foregroundColor: .white,
                prefersLargeTitles: true,
                lightModeOnly: model.settings.lightModeOnly
            )
        )
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

// MARK: - HeaderPickerControllerDelegate

extension AppComposer: HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithTitle title: String,
        style: HeroHeader.Style
    ) {
        let resolvedStyle = applySettings(to: style)
        let nextController = HeaderPickerController(
            title: title,
            navbarStyle: resolvedStyle
        )
        nextController.delegate = self
        controller.navigationController?.pushViewController(nextController, animated: true)
    }

    func headerPicker(_ controller: HeaderPickerController, showSettings _: Void) {
        presentSettings(from: controller)
    }

    private func applySettings(to style: HeroHeader.Style) -> HeroHeader.Style {
        switch style {
        case let .opaque(title, backgroundColor, foregroundColor, prefersLargeTitles, _):
            return .opaque(
                title: applyTitleLength(to: title),
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles,
                lightModeOnly: model.settings.lightModeOnly
            )
        case let .headerView(view, configuration, title):
            let largeTitleDisplayMode: HeroHeader
                .LargeTitleDisplayMode = if case .inline = configuration.largeTitleDisplayMode
            {
                .inline(.init(dimming: model.settings.dimming))
            } else if model.settings.largeTitle {
                .belowHeader(.init(
                    allowsLineWrap: model.settings.lineWrap,
                    smallTitleDisplayMode: model.settings.smallTitleDisplayMode
                ))
            } else {
                .none
            }
            let newConfiguration = HeroHeader.HeaderViewConfiguration(
                height: configuration.height,
                minHeight: configuration.minHeight,
                stretches: model.settings.stretch,
                largeTitleDisplayMode: largeTitleDisplayMode
            )
            return .headerView(
                view: view,
                configuration: newConfiguration,
                title: title.map { applyTitleLength(to: $0) }
            )
        case let .image(url, loadingType, configuration, title):
            return .image(
                url: url,
                loadingType: loadingType,
                configuration: configuration,
                title: title.map { applyTitleLength(to: $0) }
            )
        }
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

// MARK: - SettingsControllerDelegate

extension AppComposer: SettingsControllerDelegate {
    func settingsControllerDidUpdate(_ controller: SettingsController) {
        model.settings = controller.settings
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
        var largeTitle: Bool = false
        var lineWrap: Bool = false
        var smallTitleDisplayMode: HeroHeader.SmallTitleDisplayMode = .system
        var dimming: HeroHeader.InlineTitleConfiguration.Dimming = .none
        var titleLength: TitleLength = .normal
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
}
