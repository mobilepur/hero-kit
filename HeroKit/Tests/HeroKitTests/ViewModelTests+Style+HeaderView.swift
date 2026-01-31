@testable import HeroKit
import Testing
import UIKit

enum ViewModelTest {}


@MainActor
final class MockHeader: UIView {}

extension ViewModelTest {
    @Suite("HeaderView Style")
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

    func heroHeader(_ controller: UIViewController, didSetup headerView: HeroHeaderView) {
        setupHeaderHeight = headerView.frame.height
    }
}
