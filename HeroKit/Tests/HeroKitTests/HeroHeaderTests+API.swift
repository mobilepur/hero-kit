@testable import HeroKit
import Testing
import UIKit

extension HeroHeaderTests {
    enum API { }
}

extension HeroHeaderTests.API {
    @Suite("API", .serialized)
    @MainActor
    struct Integration {

        @Test("expandHeader sets state to fullyExpanded")
        func expandHeader() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav) = HeroHeaderTests.makeController()
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))
            controller.viewModel?.didCompleteSetup()

            // First collapse
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 0)
            #expect(controller.viewModel?.state == .collapsed)

            // Then expand via API
            stub.didExpandFullyWasCalled = false
            controller.expandHeader(animated: false)

            #expect(controller.viewModel?.state == .fullyExpanded)
            #expect(stub.didExpandFullyWasCalled == true)
        }

        @Test("collapseHeader sets contentOffset to zero")
        func collapseHeader() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, _, nav) = HeroHeaderTests.makeController()
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            controller.collapseHeader(animated: false)

            #expect(controller.collectionView.contentOffset.y == 0)
        }

        @Test("collapseHeaderContent sets contentOffset to hide content")
        func collapseHeaderContent() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, _, nav) = HeroHeaderTests.makeController(title: "Title")
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))
            let headerHeight = controller.viewModel?.headerHeight ?? 0

            controller.collapseHeaderContent(animated: false)

            // contentOffset.y = contentHeight - totalHeight
            let expectedOffset = configuration.height - headerHeight
            #expect(controller.collectionView.contentOffset.y == expectedOffset)
        }
    }
}
