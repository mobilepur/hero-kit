import UIKit

// MARK: - UINavigationBarAppearance

extension UINavigationBarAppearance {

    static func withStyle(
        backgroundColor: UIColor,
        foregroundColor: UIColor?
    ) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor

        if let foregroundColor {
            let textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: foregroundColor]
            appearance.titleTextAttributes = textAttributes
            appearance.largeTitleTextAttributes = textAttributes

            if #available(iOS 26, *) {
                let subtitleColor = foregroundColor.withAlphaComponent(0.85)
                let subtitleAttributes: [NSAttributedString.Key: Any] =
                    [.foregroundColor: subtitleColor]
                appearance.subtitleTextAttributes = subtitleAttributes
                appearance.largeSubtitleTextAttributes = subtitleAttributes
            }
        }

        return appearance
    }
}

// MARK: - UINavigationController

public extension UINavigationController {

    /// Applies a single appearance to all navigation bar appearance properties
    func applyAppearance(_ appearance: UINavigationBarAppearance) {
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
    }

    /// Configures navigation bar with transparent background
    func configureTransparentAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        applyAppearance(appearance)
    }

    /// Configures navigation bar with default system background
    func configureDefaultAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        applyAppearance(appearance)
    }

    /// Configures navigation bar with opaque colored background
    func configureOpaqueAppearance(backgroundColor: UIColor, foregroundColor: UIColor?) {
        let appearance = UINavigationBarAppearance.withStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        )
        applyAppearance(appearance)
    }

    /// Sets the title text color on all navigation bar appearances
    func setTitleColor(_ color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        navigationBar.standardAppearance.titleTextAttributes = attrs
        navigationBar.scrollEdgeAppearance?.titleTextAttributes = attrs
        navigationBar.compactAppearance?.titleTextAttributes = attrs
        navigationBar.compactScrollEdgeAppearance?.titleTextAttributes = attrs
    }

    /// Sets the subtitle text color on all navigation bar appearances (iOS 26+)
    @available(iOS 26, *)
    func setSubtitleColor(_ color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        navigationBar.standardAppearance.subtitleTextAttributes = attrs
        navigationBar.scrollEdgeAppearance?.subtitleTextAttributes = attrs
        navigationBar.compactAppearance?.subtitleTextAttributes = attrs
        navigationBar.compactScrollEdgeAppearance?.subtitleTextAttributes = attrs
    }
}
