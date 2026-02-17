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
            sheet.detents = [.medium()]
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
                title: title,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                prefersLargeTitles: prefersLargeTitles,
                lightModeOnly: model.settings.lightModeOnly
            )
        case .headerView:
            return style
        }
    }
}

// MARK: - SettingsControllerDelegate

extension AppComposer: SettingsControllerDelegate {
    func settingsController(
        _: SettingsController,
        didChangeLightModeOnly value: Bool
    ) {
        model.settings.lightModeOnly = value
    }
}

// MARK: - Model

extension AppComposer {
    class Model {
        var settings = AppSettings()
    }

    struct AppSettings {
        var lightModeOnly: Bool = false
    }
}
