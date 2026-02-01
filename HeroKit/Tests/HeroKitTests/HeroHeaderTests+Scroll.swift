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
        func scrollRoundTrip_noLargeTitles() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100, stretches: true)
            let (controller, stub) = HeroHeaderTests.makeController()

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))
            let headerHeight = controller.viewModel?.headerHeight ?? 100

            // 1. Initial state after setup
            #expect(stub.didSetupWasCalled == true)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // 2. Scroll down (overscroll) → stretch
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight - 50)
            #expect(stub.didStretchWasCalled == true)
            #expect(controller.viewModel?.state == .stretched)

            // 3. Scroll back to normal → unstretch
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            #expect(stub.didUnstretchWasCalled == true)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // 4. Scroll up → collapse
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 0)
            #expect(stub.didCollapseWasCalled == true)
            #expect(controller.viewModel?.state == .collapsed)

            // 5. Scroll slightly → becomes visible
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -1)
            #expect(stub.didBecameVisibleWasCalled == true)
            #expect(controller.viewModel?.state == .expanded)

            // 6. Scroll back to fully expanded
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            #expect(stub.didExpandFullyWasCalled == true)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // 7. Verify didScroll was called throughout
            #expect(stub.lastScrollOffset != nil)
        }

        @Test("Complete scroll round trip with large titles")
        func scrollRoundTrip_withLargeTitles() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                stretches: true,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub) = HeroHeaderTests.makeController(title: "Title")

            try controller.configureHeader(.headerView(view: MockHeader(), configuration: configuration))
            let headerHeight = controller.viewModel?.headerHeight ?? 100

            // 1. Initial state after setup
            #expect(stub.didSetupWasCalled == true)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // 2. Scroll down (overscroll) → stretch
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight - 50)
            #expect(stub.didStretchWasCalled == true)
            #expect(controller.viewModel?.state == .stretched)

            // 3. Scroll back to normal → unstretch
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            #expect(stub.didUnstretchWasCalled == true)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // 4. Scroll up → content hidden (large title still visible)
            // normalizedOffset = contentOffset.y + headerHeight
            // For contentHidden: normalizedOffset >= contentHeight
            // So: contentOffset.y >= contentHeight - headerHeight
            let contentThreshold = configuration.height - headerHeight
            controller.collectionView.contentOffset = CGPoint(x: 0, y: contentThreshold + 1)
            #expect(stub.didCollapseHeaderContentWasCalled == true)
            #expect(controller.viewModel?.state == .contentHidden)

            // TODO: weitere Schritte für collapse, becameVisible, etc.
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
