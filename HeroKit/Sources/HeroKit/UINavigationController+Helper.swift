import UIKit

extension UINavigationController {
    var navbarHeight: CGFloat {
        print("navigationBar height", navigationBar.frame.height)
        print("navigationBar minY", navigationBar.frame.minY)
        print("navigationBar maxY", navigationBar.frame.maxY)
        return navigationBar.frame.maxY
    }
}
