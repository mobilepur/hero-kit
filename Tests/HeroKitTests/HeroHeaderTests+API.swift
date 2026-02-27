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
        func expandHeader() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))
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
        func collapseHeader() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, _, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            controller.collapseHeader(animated: false)

            #expect(controller.collectionView.contentOffset.y == 0)
        }

        @Test("reapplyHeaderStyle fires didCollapse when collapsed")
        func reapplyCollapsed() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))
            controller.viewModel?.didCompleteSetup()

            // Collapse
            controller.collectionView.contentOffset = CGPoint(x: 0, y: 0)
            #expect(controller.viewModel?.state == .collapsed)

            // Reset flag and reapply
            stub.didCollapseWasCalled = false
            controller.reapplyHeaderStyle()

            #expect(stub.didCollapseWasCalled == true)
        }

        @Test("reapplyHeaderStyle fires headerContentDidBecameVisible when expanded")
        func reapplyExpanded() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))
            controller.viewModel?.didCompleteSetup()

            // Expand fully
            let totalHeight = controller.viewModel?.headerHeight ?? 0
            controller.collectionView.contentOffset = CGPoint(x: 0, y: -totalHeight)
            #expect(controller.viewModel?.state == .fullyExpanded)

            // Reset flag and reapply
            stub.headerContentDidBecameVisibleWasCalled = false
            controller.reapplyHeaderStyle()

            #expect(stub.headerContentDidBecameVisibleWasCalled == true)
        }

        @Test("restoresOnAppear true installs appearance observer as child")
        func restoresOnAppearTrue() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, _, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(controller.children.count == 1)
        }

        @Test("restoresOnAppear false does not install appearance observer")
        func restoresOnAppearFalse() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, _, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            try controller.setHeader(
                .headerView(view: MockHeader(), configuration: configuration),
                restoresOnAppear: false
            )

            #expect(controller.children.isEmpty)
        }

        @Test("collapseHeaderContent sets contentOffset to hide content")
        func collapseHeaderContent() {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, _, nav, window) = HeroHeaderTests.makeController(title: "Title")
            _ = (nav, window)

            let titleConfig = HeroHeader.TitleConfiguration(title: "Title")
            controller.setHeader(.headerView(
                view: MockHeader(),
                configuration: configuration,
                title: titleConfig
            ))
            let headerHeight = controller.viewModel?.headerHeight ?? 0

            controller.collapseHeaderContent(animated: false)

            // contentOffset.y = contentHeight - totalHeight
            let expectedOffset = configuration.height - headerHeight
            #expect(controller.collectionView.contentOffset.y == expectedOffset)
        }
    }
}
