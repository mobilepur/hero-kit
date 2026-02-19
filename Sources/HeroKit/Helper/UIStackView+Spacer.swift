import UIKit

extension UIStackView {
    static func spacer() -> UIView {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }
}
