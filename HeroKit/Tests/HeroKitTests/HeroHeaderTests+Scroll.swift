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

            let heroViewModel = HeroHeader.ViewModel(configuration: configuration)
            heroViewModel.delegate = stub
            heroViewModel.controller = controller
            heroViewModel.headerView = headerView

            heroViewModel.didScroll(offset: 50)

            #expect(stub.lastScrollOffset == 50)
        }
    }
}
