import ObjectiveC
import UIKit

// MARK: - Associated Object Storage

private final class WeakTransitionDelegateWrapper {
    weak var delegate: HeroTransitionDelegate?
    init(_ delegate: HeroTransitionDelegate) {
        self.delegate = delegate
    }
}

extension UIViewController {

    private enum HeroTransitionKeys {
        nonisolated(unsafe) static var matchedTransitionDelegate: Void?
        nonisolated(unsafe) static var transitionDelegate: Void?
    }

    /// Retains the `HeroMatchedTransitionDelegate` via associated object, because
    /// `UIViewController.transitioningDelegate` is a weak property.
    var heroMatchedTransitionDelegate: HeroMatchedTransitionDelegate? {
        get {
            objc_getAssociatedObject(self, &HeroTransitionKeys.matchedTransitionDelegate)
                as? HeroMatchedTransitionDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &HeroTransitionKeys.matchedTransitionDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// Delegate that receives transition lifecycle callbacks on the presenter side.
    public var heroTransitionDelegate: HeroTransitionDelegate? {
        get {
            (objc_getAssociatedObject(
                self,
                &HeroTransitionKeys.transitionDelegate
            ) as? WeakTransitionDelegateWrapper)?.delegate
        }
        set {
            objc_setAssociatedObject(
                self,
                &HeroTransitionKeys.transitionDelegate,
                newValue.map { WeakTransitionDelegateWrapper($0) },
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
