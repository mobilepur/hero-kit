import UIKit

@MainActor
public protocol HeroHeaderDelegate: AnyObject {
    func heroHeader(_ controller: UIViewController, didSetup headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didStretch headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didUnstretch headerView: HeroHeaderView)
    func heroHeader(
        _ controller: UIViewController,
        didScroll headerView: HeroHeaderView,
        offset: CGFloat
    )
    func heroHeader(
        _ controller: UIViewController,
        didCollapseHeaderContent headerView: HeroHeaderView
    )
    func heroHeader(_ controller: UIViewController, didCollapse headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didBecameVisible headerView: HeroHeaderView)
    func heroHeader(
        _ controller: UIViewController,
        headerContentDidBecameVisible headerView: HeroHeaderView
    )
    func heroHeader(_ controller: UIViewController, didExpandFully headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didShowLargeTitle headerView: HeroHeaderView)
    func heroHeader(_ controller: UIViewController, didShowSmallTitle headerView: HeroHeaderView)

}

// Default implementations (all optional)
public extension HeroHeaderDelegate {
    func heroHeader(_: UIViewController, didSetup _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didStretch _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didUnstretch _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didScroll _: HeroHeaderView, offset _: CGFloat) { }
    func heroHeader(_: UIViewController, didCollapseHeaderContent _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didCollapse _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didBecameVisible _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, headerContentDidBecameVisible _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didExpandFully _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didShowLargeTitle _: HeroHeaderView) { }
    func heroHeader(_: UIViewController, didShowSmallTitle _: HeroHeaderView) { }
}
