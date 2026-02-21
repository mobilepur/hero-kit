import UIKit

/// Convenience `UIViewControllerTransitioningDelegate` that vends
/// `HeroMatchedTransition` animators for present and dismiss.
///
/// Returns `nil` when the source has been deallocated (e.g. cell recycled),
/// causing UIKit to fall back to its default transition.
@MainActor
public class HeroMatchedTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    public weak var source: (any HeroTransitionSource)?

    public init(source: any HeroTransitionSource) {
        self.source = source
        super.init()
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let source = self.source else { return nil }
        return HeroMatchedTransition(source: source, isPresenting: true)
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard let source = self.source else { return nil }
        return HeroMatchedTransition(source: source, isPresenting: false)
    }
}
