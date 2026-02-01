import UIKit

extension HeroHeader {

    @MainActor
    final class ViewModel {
        let configuration: HeaderViewConfiguration
        var layout: Layout?
        weak var delegate: HeroHeaderDelegate?
        weak var controller: UIViewController?
        weak var headerView: HeroHeaderView?

        init(configuration: HeaderViewConfiguration) {
            self.configuration = configuration
        }

        func didSetup(layout: Layout) {
            self.layout = layout
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
