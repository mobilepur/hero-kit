import UIKit

@MainActor
public class HeroMatchedTransition: NSObject, UIViewControllerAnimatedTransitioning {

    public let duration: TimeInterval
    public let isPresenting: Bool
    public weak var source: (any HeroTransitionSource)?

    public init(
        source: any HeroTransitionSource,
        duration: TimeInterval = 0.4,
        isPresenting: Bool
    ) {
        self.duration = duration
        self.isPresenting = isPresenting
        self.source = source
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    nonisolated public func transitionDuration(
        using transitionContext: (any UIViewControllerContextTransitioning)?
    ) -> TimeInterval {
        duration
    }

    nonisolated public func animateTransition(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        MainActor.assumeIsolated {
            if isPresenting {
                animatePresentation(using: transitionContext)
            } else {
                animateDismissal(using: transitionContext)
            }
        }
    }

    // MARK: - Present

    private func animatePresentation(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        containerView.addSubview(toVC.view)
        toVC.view.layoutIfNeeded()
        toVC.view.alpha = 0

        guard let source,
              let sourceImageView = source.heroSourceImageView(),
              let window = containerView.window,
              let destination = findDestination(from: toVC)
        else {
            // Fallback: simple crossfade
            UIView.animate(withDuration: duration, animations: {
                toVC.view.alpha = 1
            }, completion: { _ in
                transitionContext.completeTransition(
                    !transitionContext.transitionWasCancelled
                )
            })
            return
        }

        let sourceFrame = source.heroSourceFrame(in: window)
        let sourceRadius = source.heroSourceCornerRadius()
        let destinationFrame = destination.heroDestinationFrame(in: window)
        let destinationRadius = destination.heroDestinationCornerRadius()
        let destinationImageView = destination.heroDestinationImageView()

        // Create snapshot
        let snapshot = UIImageView(image: sourceImageView.image)
        snapshot.contentMode = .scaleAspectFill
        snapshot.clipsToBounds = true
        snapshot.frame = sourceFrame
        snapshot.layer.cornerRadius = sourceRadius

        // Hide originals during animation
        sourceImageView.isHidden = true
        destinationImageView?.isHidden = true
        containerView.addSubview(snapshot)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: .curveEaseInOut,
            animations: {
                snapshot.frame = destinationFrame
                snapshot.layer.cornerRadius = destinationRadius
                toVC.view.alpha = 1
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                destinationImageView?.isHidden = false
                sourceImageView.isHidden = false
                transitionContext.completeTransition(
                    !transitionContext.transitionWasCancelled
                )
            }
        )
    }

    // MARK: - Dismiss

    private func animateDismissal(
        using transitionContext: any UIViewControllerContextTransitioning
    ) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        // Insert the presenting view behind the modal so it's visible during fade-out
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        containerView.insertSubview(toVC.view, at: 0)

        guard let source,
              let sourceImageView = source.heroSourceImageView(),
              let window = containerView.window,
              let destination = findDestination(from: fromVC),
              let destinationImageView = destination.heroDestinationImageView()
        else {
            // Fallback: simple fade out
            UIView.animate(withDuration: duration, animations: {
                fromVC.view.alpha = 0
            }, completion: { _ in
                transitionContext.completeTransition(
                    !transitionContext.transitionWasCancelled
                )
            })
            return
        }

        let sourceFrame = source.heroSourceFrame(in: window)
        let sourceRadius = source.heroSourceCornerRadius()
        let destinationFrame = destination.heroDestinationFrame(in: window)
        let destinationRadius = destination.heroDestinationCornerRadius()

        // Create snapshot from destination image
        let snapshot = UIImageView(image: destinationImageView.image)
        snapshot.contentMode = .scaleAspectFill
        snapshot.clipsToBounds = true
        snapshot.frame = destinationFrame
        snapshot.layer.cornerRadius = destinationRadius

        sourceImageView.isHidden = true
        destinationImageView.isHidden = true
        containerView.addSubview(snapshot)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: .curveEaseInOut,
            animations: {
                snapshot.frame = sourceFrame
                snapshot.layer.cornerRadius = sourceRadius
                fromVC.view.alpha = 0
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                sourceImageView.isHidden = false
                transitionContext.completeTransition(
                    !transitionContext.transitionWasCancelled
                )
            }
        )
    }

    // MARK: - Find Destination

    private func findDestination(
        from viewController: UIViewController
    ) -> (any HeroTransitionDestination)? {
        if let dest = viewController as? HeroTransitionDestination { return dest }
        if let nav = viewController as? UINavigationController {
            return nav.topViewController.flatMap { findDestination(from: $0) }
        }
        for child in viewController.children {
            if let dest = findDestination(from: child) { return dest }
        }
        return nil
    }
}
