@testable import HeroKit
import UIKit

enum HeroHeaderTests {
    @MainActor
    static func makeController(title: String? = nil)
    -> (MockController, StubDelegate, UINavigationController) {
        let stub = StubDelegate()
        let controller = MockController()
        controller.title = title
        controller.headerDelegate = stub

        // Embed in NavigationController for realistic testing
        let nav = UINavigationController(rootViewController: controller)
        _ = nav.view

        return (controller, stub, nav)
    }
}

// MARK: - Mocks

@MainActor
final class MockHeader: UIView { }

final class MockController: UICollectionViewController {
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Stubs

@MainActor
class StubDelegate: HeroHeaderDelegate {
    var setupHeaderHeight: CGFloat = 0
    var didSetupWasCalled = false
    var lastScrollOffset: CGFloat?
    var didStretchWasCalled = false
    var didUnstretchWasCalled = false
    var didCollapseHeaderContentWasCalled = false
    var didCollapseWasCalled = false
    var didBecameVisibleWasCalled = false
    var headerContentDidBecameVisibleWasCalled = false
    var didExpandFullyWasCalled = false

    func heroHeader(_: UIViewController, didSetup headerView: HeroHeaderView) {
        didSetupWasCalled = true
        setupHeaderHeight = headerView.frame.height
    }

    func heroHeader(_: UIViewController, didScroll _: HeroHeaderView, offset: CGFloat) {
        lastScrollOffset = offset
    }

    func heroHeader(_: UIViewController, didStretch _: HeroHeaderView) {
        didStretchWasCalled = true
    }

    func heroHeader(_: UIViewController, didUnstretch _: HeroHeaderView) {
        didUnstretchWasCalled = true
    }

    func heroHeader(_: UIViewController, didCollapseHeaderContent _: HeroHeaderView) {
        didCollapseHeaderContentWasCalled = true
    }

    func heroHeader(_: UIViewController, didCollapse _: HeroHeaderView) {
        didCollapseWasCalled = true
    }

    func heroHeader(_: UIViewController, didBecameVisible _: HeroHeaderView) {
        didBecameVisibleWasCalled = true
    }

    func heroHeader(_: UIViewController, headerContentDidBecameVisible _: HeroHeaderView) {
        headerContentDidBecameVisibleWasCalled = true
    }

    func heroHeader(_: UIViewController, didExpandFully _: HeroHeaderView) {
        didExpandFullyWasCalled = true
    }
}
