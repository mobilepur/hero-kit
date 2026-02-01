@testable import HeroKit
import UIKit

enum HeroHeaderTests {
    @MainActor
    static func makeController(title: String? = nil) -> (MockController, StubDelegate) {
        let stub = StubDelegate()
        let controller = MockController()
        controller.title = title
        controller.headerDelegate = stub
        return (controller, stub)
    }
}

// MARK: - Mocks

@MainActor
final class MockHeader: UIView {}

final class MockController: UICollectionViewController {
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Stubs

@MainActor
class StubDelegate: HeroHeaderDelegate {
    var setupHeaderHeight: CGFloat = 0
    var didSetupWasCalled = false
    var lastScrollOffset: CGFloat?
    var didCollapseWasCalled = false
    var didStretchWasCalled = false

    func heroHeader(_ controller: UIViewController, didSetup headerView: HeroHeaderView) {
        didSetupWasCalled = true
        setupHeaderHeight = headerView.frame.height
    }

    func heroHeader(_ controller: UIViewController, didScroll headerView: HeroHeaderView, offset: CGFloat) {
        lastScrollOffset = offset
    }

    func heroHeader(_ controller: UIViewController, didCollapse headerView: HeroHeaderView) {
        didCollapseWasCalled = true
    }

    func heroHeader(_ controller: UIViewController, didStretch headerView: HeroHeaderView) {
        didStretchWasCalled = true
    }
}
