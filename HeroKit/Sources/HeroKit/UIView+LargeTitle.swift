import UIKit

public extension UIView {

    /// The font used for large titles
    static let largeTitleFont = UIFont.systemFont(ofSize: 36, weight: .bold)

    /// Creates a large title label view with padding
    static func largeTitleLabel(_ title: String, allowsLineWrap: Bool = false) -> LargeTitleView {
        let largeTitle = LargeTitleView(title: title, allowsLineWrap: allowsLineWrap)
        return largeTitle
    }

    /// Creates an inline large title label for overlay on header content (bottom-left)
    static func inlineTitleLabel(_ title: String, foregroundColor: UIColor = .white) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = largeTitleFont
        titleLabel.textColor = foregroundColor
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Shadow for readability on images
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLabel.layer.shadowOpacity = 0.6
        titleLabel.layer.shadowRadius = 4

        return titleLabel
    }
}
