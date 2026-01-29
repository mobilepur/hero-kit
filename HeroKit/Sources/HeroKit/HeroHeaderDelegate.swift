import UIKit

public protocol HeroHeaderDelegate: AnyObject {
    func heroHeader(_ controller: UIViewController, didSetup headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didCollapse headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didExpand headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didHideLargeTitle headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didShowLargeTitle headerView: HeroHeaderView)
    func heroHeader(
        _ controller: UIViewController,
        didScroll headerView: HeroHeaderView,
        offset: CGFloat
    )
}

// Default implementations (all optional)
public extension HeroHeaderDelegate {
    func heroHeader(_: UIViewController, didSetup _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didCollapse _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didExpand _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didHideLargeTitle _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didShowLargeTitle _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didScroll _: HeroHeaderView, offset _: CGFloat) { }
}
