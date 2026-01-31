@testable import HeroKit
import Testing
import UIKit

enum ViewModelTest {}


@MainActor
final class MockHeader: UIView {}

extension ViewModelTest {
    @Suite("HeaderView Style", .serialized)
    @MainActor
    struct HeaderViewStyleTests {

        @Test("didSetup without LargeTitle")
        func didSetup_height() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle but no title set")
        func didSetup_height_withLargeTitle_noTitleSet() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub) = makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle and title")
        func didSetup_height_withLargeTitle() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub) = makeController(title: "Title")

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight > configuration.height)
        }


        @Test("ViewModel has correct headerHeight after setup")
        func viewModel_headerHeight() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = makeController()
            _ = stub

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(controller.viewModel?.headerHeight == configuration.height)
        }

        @Test("didSetup delegate is called")
        func didSetup_delegateCalled() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.didSetupWasCalled == true)
        }
    }
}

extension ViewModelTest.HeaderViewStyleTests {

    // MARK: - Helper

    private func makeController(title: String? = nil) -> (MockController, StubDelegate) {
        let stub = StubDelegate()
        let controller = MockController()
        controller.title = title
        controller.headerDelegate = stub
        return (controller, stub)
    }
}

// MARK: - Scroll Tests

extension ViewModelTest {
    @Suite("Scroll", .serialized)
    @MainActor
    struct ScrollTests {

        @Test("didScroll delegate is called when scrolling")
        func didScroll_delegateCalled() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            // Simulate scroll
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 50)

            #expect(stub.lastScrollOffset != nil)
        }

        // MARK: - Helper

        private func makeController(title: String? = nil) -> (MockController, StubDelegate) {
            let stub = StubDelegate()
            let controller = MockController()
            controller.title = title
            controller.headerDelegate = stub
            return (controller, stub)
        }
    }
}


// MARK: - Helper 
final class MockController: UICollectionViewController {
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
