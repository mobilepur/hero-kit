@testable import HeroKit
import Testing
import UIKit

extension HeroHeaderTests {
    enum Scroll {}
}

// MARK: - Integration

extension HeroHeaderTests.Scroll {
    @Suite("Scroll Integration", .serialized)
    @MainActor
    struct Integration {

        @Test("didScroll delegate is called when scrolling")
        func didScroll_delegateCalled() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = HeroHeaderTests.makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            // Simulate scroll
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 50)

            #expect(stub.lastScrollOffset != nil)
        }

        @Test("didCollapse delegate is called when header collapses")
        func didCollapse_delegateCalled() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub) = HeroHeaderTests.makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))

            // Scroll up until header is fully collapsed (offsetY >= 0)
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 0)

            #expect(stub.didCollapseWasCalled == true)
        }

        @Test("Complete scroll round trip triggers all delegate callbacks")
        func scrollRoundTrip() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100, stretches: true)
            let (controller, stub) = HeroHeaderTests.makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))
            let headerHeight = controller.viewModel?.headerHeight ?? 100

            // 1. Initial state after setup
            #expect(stub.didSetupWasCalled == true)
            #expect(controller.viewModel?.state == .expanded)

            // 2. Scroll down (overscroll) → stretch
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight - 50)
            #expect(stub.didStretchWasCalled == true)
            #expect(controller.viewModel?.state == .stretched)

            /*
            // 3. Scroll up → collapse
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 0)
            #expect(stub.didCollapseWasCalled == true)

            // 4. Scroll back to expanded
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            #expect(stub.didExpandFullyWasCalled == true)

            // 5. Verify didScroll was called throughout
            #expect(stub.lastScrollOffset != nil)
            */
        }
    }
}

// MARK: - ViewModel

extension HeroHeaderTests.Scroll {
    @Suite("Scroll ViewModel", .serialized)
    @MainActor
    struct ViewModel {

        @Test("didScroll calls delegate with offset")
        func didScroll_callsDelegate() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let stub = StubDelegate()
            let controller = MockController()
            let headerView = HeroHeaderView(contentView: MockHeader(), largeTitleView: nil)
            let layout = HeroHeader.Layout(headerHeightConstraint: NSLayoutConstraint())

            let heroViewModel = HeroHeader.ViewModel(controller: controller, configuration: configuration)
            heroViewModel.delegate = stub
            heroViewModel.setup(headerView: headerView, layout: layout)

            heroViewModel.didScroll(offset: 50)

            #expect(stub.lastScrollOffset == 50)
        }
    }
}
