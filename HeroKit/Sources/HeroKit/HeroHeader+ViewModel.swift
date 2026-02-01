import UIKit

extension HeroHeader {

    @MainActor
    final class ViewModel {
        let configuration: HeaderViewConfiguration
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        private(set) var headerView: HeroHeaderView?
        private(set) var layout: Layout?

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
