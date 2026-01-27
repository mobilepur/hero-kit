import Combine
import UIKit

public extension UIViewController {

    func subscribeToScrollOffset(of scrollView: UIScrollView) -> AnyCancellable {
        scrollView.publisher(for: \.contentOffset)
            .sink { offset in
                print("Scroll offset: \(offset.y)")
            }
    }
}
