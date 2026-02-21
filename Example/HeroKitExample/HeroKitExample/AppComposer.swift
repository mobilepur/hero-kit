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
            navbarStyle: model.buildStyle(from: launcherContent)
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

// MARK: - HeaderPickerControllerDelegate

extension AppComposer: HeaderPickerControllerDelegate {

    func headerPicker(
        _ controller: HeaderPickerController,
        didSelect content: HeaderContent,
        transitionSource: (any HeroTransitionSource)?
    ) {
        let resolvedStyle = model.buildStyle(from: content)
        let nextController = HeaderPickerController(
            title: content.displayName,
            navbarStyle: resolvedStyle
        )
        nextController.content = content
        nextController.delegate = self

        if let transitionSource {
            let nav = UINavigationController(rootViewController: nextController)
            controller.heroPresent(nav, source: transitionSource)
        } else {
            controller.navigationController?.pushViewController(nextController, animated: true)
        }
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
        let resolvedStyle = model.buildStyle(from: content)
        topController.setHeader(resolvedStyle)
    }
}
