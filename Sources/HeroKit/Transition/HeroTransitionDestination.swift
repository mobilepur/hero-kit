import UIKit

/// Implemented by the destination view controller that receives the animated
/// image during a matched transition.
@MainActor
public protocol HeroTransitionDestination: AnyObject {
    /// The image view that receives the animated image.
    func heroDestinationImageView() -> UIImageView?
    /// The target frame in window coordinates.
    func heroDestinationFrame(in window: UIWindow) -> CGRect
    /// Corner radius of the destination view.
    func heroDestinationCornerRadius() -> CGFloat
}
