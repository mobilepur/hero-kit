import ObjectiveC
import UIKit

// MARK: - Associated Object Storage

extension UIViewController {

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
