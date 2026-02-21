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
        func didSetup_height() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle but no title set")
        func didSetup_height_withLargeTitle_noTitleSet() {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.setupHeaderHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle and title")
        func didSetup_height_withLargeTitle() {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let (controller, stub, nav, window) = HeroHeaderTests.makeController(title: "Title")
            _ = (nav, window)

            let titleConfig = HeroHeader.TitleConfiguration(title: "Title")
            controller.setHeader(.headerView(
                view: MockHeader(),
                configuration: configuration,
                title: titleConfig
            ))

            #expect(stub.setupHeaderHeight > configuration.height)
        }

        @Test("ViewModel has correct headerHeight after setup")
        func viewModel_headerHeight() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (stub, nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(controller.viewModel?.headerHeight == configuration.height)
        }

        @Test("didSetup delegate is called")
        func didSetup_delegateCalled() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let (controller, stub, nav, window) = HeroHeaderTests.makeController()
            _ = (nav, window)

            controller.setHeader(.headerView(view: MockHeader(), configuration: configuration))

            #expect(stub.didSetupWasCalled == true)
        }
    }
}
