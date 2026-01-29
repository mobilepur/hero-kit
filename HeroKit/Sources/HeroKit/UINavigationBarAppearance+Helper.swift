import UIKit

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
                appearance.largeSubtitleTextAttributes = textAttributes
            }
        }

        return appearance
    }

}
