import ObjectiveC
import UIKit

public extension UIViewController {

    /// Presents the destination modally with a matched-element transition.
    ///
    /// The source view's image morphs into the destination's header image.
    /// On dismiss, the animation reverses automatically.
    func heroPresent(
        _ destination: UIViewController,
        source: any HeroTransitionSource,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let transitionDelegate = HeroMatchedTransitionDelegate(source: source)
        destination.heroTransitionDelegate = transitionDelegate
        destination.transitioningDelegate = transitionDelegate
        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: animated, completion: completion)
    }
}

// MARK: - Associated Object Storage

private extension UIViewController {

    enum HeroTransitionKeys {
        nonisolated(unsafe) static var transitionDelegate: Void?
    }

    /// Retains the transition delegate via associated object, because
    /// `UIViewController.transitioningDelegate` is a weak property.
    var heroTransitionDelegate: HeroMatchedTransitionDelegate? {
        get {
            objc_getAssociatedObject(self, &HeroTransitionKeys.transitionDelegate)
                as? HeroMatchedTransitionDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &HeroTransitionKeys.transitionDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
