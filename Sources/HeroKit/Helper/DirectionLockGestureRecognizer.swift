import UIKit
import UIKit.UIGestureRecognizerSubclass

/// A pan gesture recognizer that only begins for horizontal drags inside the gallery area.
///
/// - Touch **outside** gallery area → `.failed` immediately
/// - **Vertical** drag in gallery → `.failed` (parent scroll view can proceed)
/// - **Horizontal** drag in gallery → begins as normal `UIPanGestureRecognizer`
///
/// Once classified, the direction is locked for the remainder of the touch.
/// Use `parentScrollView.panGestureRecognizer.require(toFail: galleryPan)` so
/// the parent scroll view waits for this gesture to resolve before scrolling.
final class GalleryPanGestureRecognizer: UIPanGestureRecognizer {

    weak var galleryAreaView: UIView?

    private var initialPoint: CGPoint?
    private var directionResolved = false
    private let classificationThreshold: CGFloat = 8

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        directionResolved = false

        guard let touch = touches.first else {
            state = .failed
            return
        }

        initialPoint = touch.location(in: view)

        if !isTouchInsideGalleryArea(touch) {
            state = .failed
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let initial = initialPoint, !directionResolved else {
            super.touchesMoved(touches, with: event)
            return
        }

        guard let touch = touches.first else {
            super.touchesMoved(touches, with: event)
            return
        }

        let current = touch.location(in: view)
        let dx = abs(current.x - initial.x)
        let dy = abs(current.y - initial.y)

        if dx >= classificationThreshold || dy >= classificationThreshold {
            directionResolved = true
            if dy > dx {
                state = .failed
                return
            }
        }

        super.touchesMoved(touches, with: event)
    }

    override func reset() {
        super.reset()
        initialPoint = nil
        directionResolved = false
    }

    private func isTouchInsideGalleryArea(_ touch: UITouch) -> Bool {
        guard let galleryAreaView else { return false }
        let location = touch.location(in: galleryAreaView)
        return galleryAreaView.bounds.contains(location)
    }
}
