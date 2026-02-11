@testable import HeroKit
import Testing
import UIKit

extension HeroHeaderTests {
    enum Setup { }
}

extension HeroHeaderTests.Setup {
    @Suite("Setup Integration", .serialized)
    @MainActor
    struct Integration {

        @Test("didSetup without LargeTitle")
        func didSetup_height() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav) = HeroHeaderTests.makeController()
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle but no title set")
        func didSetup_height_withLargeTitle_noTitleSet() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub, nav) = HeroHeaderTests.makeController()
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle and title")
        func didSetup_height_withLargeTitle() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub, nav) = HeroHeaderTests.makeController(title: "Title")
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight > configuration.height)
        }

        @Test("ViewModel has correct headerHeight after setup")
        func viewModel_headerHeight() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav) = HeroHeaderTests.makeController()
            _ = (stub, nav)

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(controller.viewModel?.headerHeight == configuration.height)
        }

        @Test("didSetup delegate is called")
        func didSetup_delegateCalled() throws {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav) = HeroHeaderTests.makeController()
            _ = nav

            try controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.didSetupWasCalled == true)
        }
    }
}
