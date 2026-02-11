import Combine
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
        let style: Style
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        private(set) var headerView: HeroHeaderView?
        private(set) var layout: Layout?
        private(set) var state: State = .fullyExpanded
        var storedTitle: String?
        private var titleCancellable: AnyCancellable?
        private var isInitialScrollComplete = false

        func didCompleteSetup() {
            isInitialScrollComplete = true
        }

        var headerViewConfiguration: HeaderViewConfiguration? {
            style.headerViewConfiguration
        }

        var titleConfiguration: TitleConfiguration? {
            style.titleConfiguration
        }

        init(controller: UIViewController, style: Style) {
            self.controller = controller
            self.style = style
            observeTitleChanges()
        }

        private func observeTitleChanges() {
            titleCancellable = controller?.publisher(for: \.title)
                .sink { [weak self] newTitle in
                    guard let self, let controller, let headerView, let newTitle else { return }
                    storedTitle = newTitle

                    // Update large title view
                    (headerView.largeTitleView as? LargeTitleView)?.updateTitle(newTitle)

                    // UIKit syncs viewController.title to navigationItem.title automatically,
                    // so we must explicitly control small title visibility
                    if headerView.isLargeTitleHidden {
                        controller.navigationItem.title = newTitle
                    } else {
                        controller.navigationItem.title = nil
                    }

                    delegate?.heroHeader(controller, didUpdateTitle: headerView, title: newTitle)
                }
        }

        func setup(headerView: HeroHeaderView, layout: Layout) {
            guard let controller else { return }
            self.headerView = headerView
            self.layout = layout
            applySmallTitleVisibility()
            delegate?.heroHeader(controller, didSetup: headerView)
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
            guard let layout, let headerViewConfiguration else { return }
            // Scroll to hide content but keep large title visible
            let targetOffset = CGPoint(x: 0, y: headerViewConfiguration.height - layout.totalHeight)
            scrollView?.setContentOffset(targetOffset, animated: animated)
        }

        func collapseHeader(animated: Bool) {
            // Scroll to fully collapse - offset 0 means header is behind nav bar
            let targetOffset = CGPoint(x: 0, y: 0)
            scrollView?.setContentOffset(targetOffset, animated: animated)
        }

        func didScroll(offset: CGFloat) {
            guard isInitialScrollComplete else { return }
            guard let layout, let headerView, let headerViewConfiguration else { return }

            let invertedOffset = -offset
            updateConstraints(
                invertedOffset: invertedOffset,
                layout: layout,
                headerView: headerView,
                config: headerViewConfiguration
            )
            updateLargeTitleVisibility(
                invertedOffset: invertedOffset,
                layout: layout,
                headerView: headerView,
                config: headerViewConfiguration
            )

            let normalizedOffset = offset + layout.totalHeight
            updateState(for: normalizedOffset)
            applySmallTitleVisibility(offset: normalizedOffset)
        }

        private func updateConstraints(
            invertedOffset: CGFloat,
            layout: Layout,
            headerView _: HeroHeaderView,
            config: HeroHeader.HeaderViewConfiguration
        ) {
            let totalHeight = layout.totalHeight

            if invertedOffset > totalHeight, config.stretches {
                let stretchAmount = invertedOffset - totalHeight
                layout.headerHeightConstraint.constant = invertedOffset
                layout.contentHeightConstraint.constant = config.height + stretchAmount
                layout.headerTopConstraint.constant = 0
            } else if invertedOffset < totalHeight {
                let minOffset = max(config.minHeight ?? 0, invertedOffset)
                layout.headerTopConstraint.constant = minOffset - totalHeight
                layout.headerHeightConstraint.constant = totalHeight
                layout.contentHeightConstraint.constant = config.height
            } else {
                layout.headerTopConstraint.constant = 0
                layout.headerHeightConstraint.constant = totalHeight
                layout.contentHeightConstraint.constant = config.height
            }
        }

        private func updateLargeTitleVisibility(
            invertedOffset: CGFloat,
            layout: Layout,
            headerView: HeroHeaderView,
            config: HeroHeader.HeaderViewConfiguration
        ) {
            let totalHeight = layout.totalHeight

            guard invertedOffset < totalHeight else {
                headerView.largeTitleView?.alpha = 1
                (headerView.largeTitleView as? LargeTitleView)?.blurFraction(0)
                return
            }

            let largeTitleHeight = totalHeight - config.height
            let largeTitleTop = invertedOffset - largeTitleHeight

            let navBarBottom = controller?.navigationController?.navigationBar.frame.maxY ?? 0
            let statusBarBottom = controller?.view.window?.safeAreaInsets.top ?? 0

            let hiddenThreshold: CGFloat
            let fogThreshold: CGFloat

            if case .inline = config.largeTitleDisplayMode {
                hiddenThreshold = navBarBottom
                fogThreshold = navBarBottom + 60
            } else {
                hiddenThreshold = statusBarBottom
                fogThreshold = navBarBottom
            }

            if largeTitleTop <= hiddenThreshold {
                (headerView.largeTitleView as? LargeTitleView)?.blurFraction(1)
                headerView.largeTitleView?.alpha = 0
            } else if largeTitleTop < fogThreshold {
                let fraction = 1 - (largeTitleTop - hiddenThreshold) /
                    (fogThreshold - hiddenThreshold)
                (headerView.largeTitleView as? LargeTitleView)?.blurFraction(fraction)
                headerView.largeTitleView?.alpha = 1
            } else {
                (headerView.largeTitleView as? LargeTitleView)?.blurFraction(0)
                headerView.largeTitleView?.alpha = 1
            }
        }

        private func applySmallTitleVisibility(offset _: CGFloat = 0) {
            guard let controller, let headerView, let headerViewConfiguration else { return }

            let shouldShow: Bool = switch headerViewConfiguration.largeTitleDisplayMode {
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
                headerView.isLargeTitleHidden
            }

            let wasShowing = controller.navigationItem.title != nil
            if shouldShow != wasShowing {
                let newTitle = shouldShow ? storedTitle : nil
                controller.navigationController?.setTitleAnimated(newTitle)

                // iOS 26+: Set subtitle when small title is shown
                if #available(iOS 26, *) {
                    controller.navigationItem.subtitle = shouldShow ? titleConfiguration?
                        .subtitle : nil
                }

                // Notify delegate of title visibility change
                if shouldShow {
                    delegate?.heroHeader(controller, didShowSmallTitle: headerView)
                } else {
                    delegate?.heroHeader(controller, didShowLargeTitle: headerView)
                }
            }
        }

        private func updateState(for offset: CGFloat) {
            guard let controller, let headerView, let headerViewConfiguration else { return }

            let previousState = state
            let contentHeight = headerViewConfiguration.height

            // Calculate new state based on offset
            if offset < 0, headerViewConfiguration.stretches {
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
