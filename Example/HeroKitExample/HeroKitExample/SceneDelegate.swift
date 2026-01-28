import HeroKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let controller = HeaderPickerController(navbarStyle: .color(
            backgroundColor: .systemBlue,
            foregroundColor: .white
        ))
        controller.delegate = self

        let nav = UINavigationController(rootViewController: controller)
        // nav.navigationBar.prefersLargeTitles = true

        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}

extension SceneDelegate: HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithHeaderStyle style: HeroHeader.Style
    ) {
        let nextController = HeaderPickerController(navbarStyle: style)
        nextController.delegate = self
        controller.navigationController?.pushViewController(nextController, animated: true)
    }
}
