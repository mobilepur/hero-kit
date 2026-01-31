import UIKit

extension HeroHeader {

    final class ViewModel {
        let configuration: HeaderViewConfiguration

        init(configuration: HeaderViewConfiguration) {
            self.configuration = configuration
        }

        func didSetup() {
            
        }

        func didScroll(offset: CGFloat) {
        }
    }
}
