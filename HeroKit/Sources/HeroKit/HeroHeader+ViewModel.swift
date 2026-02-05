import UIKit

extension HeroHeader {

    public enum State {
        case stretched // Overscroll - header is stretched
        case fullyExpanded // Default state - header at rest position
        case expanded // Header visible but not fully expanded
        case contentHidden // Content behind nav bar, large title still visible
        case collapsed // Fully collapsed - only nav bar visible
    }

    @MainActor
    final class ViewModel {
        let configuration: HeaderViewConfiguration
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        private(set) var headerView: HeroHeaderView?
        private(set) var layout: Layout?
        private(set) var state: State = .fullyExpanded
        var storedTitle: String?

        init(controller: UIViewController, configuration: HeaderViewConfiguration) {
            self.controller = controller
            self.configuration = configuration
        }

        func setup(headerView: HeroHeaderView, layout: Layout) {
            self.headerView = headerView
            self.layout = layout
            applySmallTitleVisibility()
            delegate?.heroHeader(controller!, didSetup: headerView)
        }

        var headerHeight: CGFloat {
            layout?.totalHeight ?? 0
        }

        var scrollView: UIScrollView? {
            controller?.findScrollView()
        }

        // MARK: - Public API

        func expandHeader(animated: Bool) {
            guard let layout else { return }
            let targetOffset = CGPoint(x: 0, y: -layout.totalHeight)
            scrollView?.setContentOffset(targetOffset, animated: animated)
        }

        func collapseHeaderContent(animated: Bool) {
            guard let layout else { return }
            // Scroll to hide content but keep large title visible
            let targetOffset = CGPoint(x: 0, y: configuration.height - layout.totalHeight)
            scrollView?.setContentOffset(targetOffset, animated: animated)
        }

        func collapseHeader(animated: Bool) {
            // Scroll to fully collapse - offset 0 means header is behind nav bar
            let targetOffset = CGPoint(x: 0, y: 0)
            scrollView?.setContentOffset(targetOffset, animated: animated)
        }

        func didScroll(offset: CGFloat) {
            guard let layout, let headerView else { return }

            let invertedOffset = -offset
            let totalHeight = layout.totalHeight
            let effectiveMinHeight = configuration.minHeight ?? 0

            if invertedOffset > totalHeight, configuration.stretches {
                // Overscroll - stretch effect
                let stretchAmount = invertedOffset - totalHeight
                layout.headerHeightConstraint.constant = invertedOffset
                layout.contentHeightConstraint.constant = configuration.height + stretchAmount
                layout.headerTopConstraint.constant = 0

                //    headerView.isLargeTitleHidden = false

            } else if invertedOffset < totalHeight {
                // Header collapsing
                let minOffset = max(effectiveMinHeight, invertedOffset)
                layout.headerTopConstraint.constant = minOffset - totalHeight
                layout.headerHeightConstraint.constant = totalHeight
                layout.contentHeightConstraint.constant = configuration.height

                // LargeTitle hidden when scrolled behind nav bar
                let largeTitleHeight = totalHeight - configuration.height
                //  headerView.isLargeTitleHidden = invertedOffset < largeTitleHeight

            } else {
                // Normal expanded state
                layout.headerTopConstraint.constant = 0
                layout.headerHeightConstraint.constant = totalHeight
                layout.contentHeightConstraint.constant = configuration.height

                // headerView.isLargeTitleHidden = false
            }

            // Update state and call delegates
            let normalizedOffset = offset + totalHeight
            updateState(for: normalizedOffset)

            // Update small title visibility
            applySmallTitleVisibility(offset: normalizedOffset)
        }

        private func applySmallTitleVisibility(offset: CGFloat = 0) {
            guard let controller, let headerView else { return }

            let shouldShow: Bool = switch configuration.largeTitleDisplayMode {
            case .none:
                // No large title, always show small title
                true
            case let .belowHeader(config):
                switch config.smallTitleDisplayMode {
                case .never:
                    false
                case .always:
                    true
                case .system:
                    headerView.isLargeTitleHidden
                }
            case .inline:
                headerView.isCollapsed
            }

            let wasShowing = controller.navigationItem.title != nil
            if shouldShow != wasShowing {
                print(
                    "SmallTitle: \(shouldShow ? "showing" : "hiding") '\(storedTitle ?? "")' at offset \(offset)"
                )
            }
            controller.navigationItem.title = shouldShow ? storedTitle : nil
        }

        private func updateState(for offset: CGFloat) {
            guard let controller, let headerView else { return }

            let previousState = state
            let contentHeight = configuration.height

            // Calculate new state based on offset
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
