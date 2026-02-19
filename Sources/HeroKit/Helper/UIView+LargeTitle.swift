import UIKit

public extension UIView {

    /// The font used for large titles
    static let largeTitleFont = UIFont.systemFont(ofSize: 36, weight: .bold)

    /// Creates a large title label view with padding
    static func largeTitleLabel(
        title: String,
        subtitle: String?,
        allowsLineWrap: Bool = false,
        insets: HeroHeader.TitleInsets = .init()
    ) -> LargeTitleView {
        let resolved = (
            top: insets.top ?? 6,
            leading: insets.leading ?? 16,
            bottom: insets.bottom ?? 8,
            trailing: insets.trailing ?? 16
        )
        return LargeTitleView(
            title: title,
            subtitle: subtitle,
            allowsLineWrap: allowsLineWrap,
            titleInsets: resolved
        )
    }

    /// Creates an inline large title label for overlay on header content (bottom-left)
    static func inlineTitleLabel(_ title: String, foregroundColor: UIColor = .white) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = largeTitleFont
        titleLabel.textColor = foregroundColor
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        return titleLabel
    }
}
