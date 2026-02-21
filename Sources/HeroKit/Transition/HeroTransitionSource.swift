import UIKit

/// Implemented by the source view (e.g. a collection view cell) whose image
/// will be animated to the destination during a matched transition.
@MainActor
public protocol HeroTransitionSource: AnyObject {
    /// The image view whose content will be animated to the destination.
    func heroSourceImageView() -> UIImageView?
    /// The frame in window coordinates for the starting position.
    func heroSourceFrame(in window: UIWindow) -> CGRect
    /// Corner radius of the source view (animated to the destination radius).
    func heroSourceCornerRadius() -> CGFloat
}
