import UIKit

// MARK: - Inline Title / Dimming

extension UIView {

    @discardableResult
    func addInlineTitleLabel(
        title: String,
        subtitle: String?,
        foregroundColor: UIColor,
        dimming: HeroHeader.InlineTitleConfiguration.Dimming,
        insets: HeroHeader.TitleInsets = .init()
    ) -> LargeTitleView {
        let resolved = (
            top: insets.top ?? 0,
            leading: insets.leading ?? 16,
            bottom: insets.bottom ?? 16,
            trailing: insets.trailing ?? 16
        )
        let hasFog = backgroundColor != nil
        let fogColor = backgroundColor ?? .systemBackground
        let titleView = LargeTitleView(
            title: title,
            subtitle: subtitle,
            foregroundColor: foregroundColor,
            fog: hasFog,
            fogColor: fogColor,
            titleInsets: resolved
        )
        titleView.translatesAutoresizingMaskIntoConstraints = false

        if dimming != .none {
            let dimmingView = Self.createDimmingView(gradient: dimming == .gradient)
            addSubview(dimmingView)
            dimmingView.pinToEdges(of: self)
        }

        addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            titleView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        return titleView
    }

    static func createDimmingView(gradient: Bool) -> UIView {
        if gradient {
            let dimmingView = GradientDimmingView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.isUserInteractionEnabled = false
            return dimmingView
        } else {
            let dimmingView = UIView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.isUserInteractionEnabled = false
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            return dimmingView
        }
    }

    func pinToEdges(of parent: UIView) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        ])
    }
}
