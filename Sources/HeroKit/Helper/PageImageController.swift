import UIKit

final class PageImageView: UIControl {
    var hitTestingEnabled: Bool = true

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hitTestingEnabled else { return nil }
        return super.point(inside: point, with: event) ? self : nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard hitTestingEnabled else { return false }
        return super.point(inside: point, with: event)
    }
}
