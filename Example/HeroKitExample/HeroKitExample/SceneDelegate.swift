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

        let controller = HeaderPickerController(
            title: "Style Picker",
            navbarStyle: nil
        )
        controller.delegate = self

        let nav = UINavigationController(rootViewController: controller)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}

extension SceneDelegate: HeaderPickerControllerDelegate {
    func headerPicker(
        _ controller: HeaderPickerController,
        didPickCellWithTitle title: String,
        style: HeroHeader.Style
    ) {
        let nextController = HeaderPickerController(
            title: title,
            navbarStyle: style
        )
        nextController.delegate = self
        controller.navigationController?.pushViewController(nextController, animated: true)
    }
}
