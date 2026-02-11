import UIKit

extension UINavigationController {

    func setTitleAnimated(_ title: String?, duration: TimeInterval = 0.3) {
        let transition = CATransition()
        transition.type = .fade
        transition.duration = duration
        navigationBar.layer.add(transition, forKey: "titleFade")
        topViewController?.navigationItem.title = title
    }
}
