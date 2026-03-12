import UIKit

@MainActor
public protocol HeroTransitionDelegate: AnyObject {
    func heroTransition(
        _ presenter: UIViewController,
        willPresent destination: UIViewController
    )
    func heroTransition(
        _ presenter: UIViewController,
        didPresent destination: UIViewController
    )
    func heroTransition(
        _ presenter: UIViewController,
        willDismiss destination: UIViewController
    )
    func heroTransition(
        _ presenter: UIViewController,
        didDismiss destination: UIViewController
    )
}

/// Default implementations (all optional)
public extension HeroTransitionDelegate {
    func heroTransition(_: UIViewController, willPresent _: UIViewController) { }
    func heroTransition(_: UIViewController, didPresent _: UIViewController) { }
    func heroTransition(_: UIViewController, willDismiss _: UIViewController) { }
    func heroTransition(_: UIViewController, didDismiss _: UIViewController) { }
}
