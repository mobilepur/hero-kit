import UIKit

extension HeroHeader {

    public enum State {
        case stretched      // Overscroll - header is stretched
        case expanded       // Default state - content and large title visible
        case contentHidden  // Content behind nav bar, large title still visible
        case collapsed      // Fully collapsed - only nav bar visible
    }

    @MainActor
    final class ViewModel {
        let configuration: HeaderViewConfiguration
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        private(set) var headerView: HeroHeaderView?
        private(set) var layout: Layout?
        private(set) var state: State = .expanded

        init(controller: UIViewController, configuration: HeaderViewConfiguration) {
            self.controller = controller
            self.configuration = configuration
        }

        func setup(headerView: HeroHeaderView, layout: Layout) {
            self.headerView = headerView
            self.layout = layout
            delegate?.heroHeader(controller!, didSetup: headerView)
        }

        var headerHeight: CGFloat {
            layout?.headerHeightConstraint.constant ?? 0
        }

        func didScroll(offset: CGFloat) {
            guard let controller, let headerView else { return }

            let previousState = state

            // Calculate new state based on offset
            // offset = 0 → fully expanded
            // offset < 0 → overscroll (stretching)
            // offset >= headerHeight → collapsed
            if offset < 0, configuration.stretches {
                state = .stretched
            } else if offset >= headerHeight {
                state = .collapsed
            } else {
                state = .expanded
            }

            // Call delegate for state changes
            if state != previousState {
                switch state {
                case .stretched:
                    delegate?.heroHeader(controller, didStretch: headerView)
                case .collapsed:
                    delegate?.heroHeader(controller, didCollapse: headerView)
                case .expanded where previousState == .collapsed:
                    delegate?.heroHeader(controller, didBecameVisible: headerView)
                case .expanded where previousState == .stretched:
                    delegate?.heroHeader(controller, didUnstretch: headerView)
                default:
                    break
                }
            }

            delegate?.heroHeader(controller, didScroll: headerView, offset: offset)
        }
    }

    final class Layout {
        let headerHeightConstraint: NSLayoutConstraint

        init(headerHeightConstraint: NSLayoutConstraint) {
            self.headerHeightConstraint = headerHeightConstraint
        }
    }
}
