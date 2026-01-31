import UIKit

extension HeroHeader {

    final class ViewModel {
        let configuration: HeaderViewConfiguration
        var layout: Layout?

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
        }
    }

    final class Layout {
        let headerHeightConstraint: NSLayoutConstraint

        init(headerHeightConstraint: NSLayoutConstraint) {
            self.headerHeightConstraint = headerHeightConstraint
        }
    }
}
