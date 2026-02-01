import UIKit

extension HeroHeader {

    public enum State {
        case stretched       // Overscroll - header is stretched
        case fullyExpanded   // Default state - header at rest position
        case expanded        // Header visible but not fully expanded
        case contentHidden   // Content behind nav bar, large title still visible
        case collapsed       // Fully collapsed - only nav bar visible
    }

    @MainActor
    final class ViewModel {
        let configuration: HeaderViewConfiguration
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        private(set) var headerView: HeroHeaderView?
        private(set) var layout: Layout?
        private(set) var state: State = .fullyExpanded

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
            layout?.totalHeight ?? 0
        }

        func didScroll(offset: CGFloat) {
            guard let controller, let headerView else { return }

            let previousState = state
            let contentHeight = configuration.height

            // Calculate new state based on offset
            // offset < 0 → overscroll (stretching)
            // offset == 0 → fully expanded (rest position)
            // 0 < offset < contentHeight → expanded (visible but not fully)
            // contentHeight <= offset < headerHeight → contentHidden (large title still visible)
            // offset >= headerHeight → collapsed

            if offset < 0, configuration.stretches {
                state = .stretched
            } else if offset >= headerHeight {
                state = .collapsed
            } else if offset >= contentHeight {
                state = .contentHidden
            } else if offset == 0 {
                state = .fullyExpanded
            } else {
                state = .expanded
            }

            // Call delegate for state changes
            if state != previousState {
                // Unstretch when leaving stretched state
                if previousState == .stretched {
                    delegate?.heroHeader(controller, didUnstretch: headerView)
                }

                switch state {
                case .stretched:
                    delegate?.heroHeader(controller, didStretch: headerView)
                case .fullyExpanded:
                    delegate?.heroHeader(controller, didExpandFully: headerView)
                case .contentHidden where previousState == .collapsed:
                    delegate?.heroHeader(controller, didBecameVisible: headerView)
                case .contentHidden:
                    delegate?.heroHeader(controller, didCollapseHeaderContent: headerView)
                case .collapsed:
                    delegate?.heroHeader(controller, didCollapse: headerView)
                case .expanded where previousState == .collapsed:
                    delegate?.heroHeader(controller, didBecameVisible: headerView)
                case .expanded where previousState == .contentHidden:
                    delegate?.heroHeader(controller, headerContentDidBecameVisible: headerView)
                default:
                    break
                }
            }

            delegate?.heroHeader(controller, didScroll: headerView, offset: offset)
        }
    }

    final class Layout {
        let headerTopConstraint: NSLayoutConstraint
        let headerHeightConstraint: NSLayoutConstraint
        let contentHeightConstraint: NSLayoutConstraint
        let totalHeight: CGFloat

        init(
            headerTopConstraint: NSLayoutConstraint,
            headerHeightConstraint: NSLayoutConstraint,
            contentHeightConstraint: NSLayoutConstraint,
            totalHeight: CGFloat
        ) {
            self.headerTopConstraint = headerTopConstraint
            self.headerHeightConstraint = headerHeightConstraint
            self.contentHeightConstraint = contentHeightConstraint
            self.totalHeight = totalHeight
        }
    }
}
