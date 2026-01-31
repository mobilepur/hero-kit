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

        @Test("didSetup without LargeTitle sets headerHeight to configuration.height")
        func didSetup_noLargeTitle_height() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let sut = HeroHeader.ViewModel(configuration: configuration)

            // Setup content with real constraints
            let contentView = MockHeader()
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.heightAnchor.constraint(equalToConstant: configuration.height).isActive = true

            let headerView = HeroHeaderView(contentView: contentView)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.widthAnchor.constraint(equalToConstant: 300).isActive = true
            headerView.layoutIfNeeded()

            let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: headerView.frame.height)
            let layout = HeroHeader.Layout(headerHeightConstraint: headerHeightConstraint)

            sut.didSetup(layout: layout)

            #expect(sut.headerHeight == configuration.height)
        }

        @Test("didSetup with LargeTitle (single line) sets headerHeight to content + title height")
        func didSetup_largeTitle_singleLine_height() {
            let configuration = HeroHeader.HeaderViewConfiguration(
                height: 100,
                largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: false))
            )
            let sut = HeroHeader.ViewModel(configuration: configuration)

            // Setup content with real constraints
            let contentView = MockHeader()
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.heightAnchor.constraint(equalToConstant: configuration.height).isActive = true

            let largeTitleView = UIView.largeTitleLabel("Title")

            let headerView = HeroHeaderView(contentView: contentView, largeTitleView: largeTitleView)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.widthAnchor.constraint(equalToConstant: 300).isActive = true
            headerView.layoutIfNeeded()

            let headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: headerView.frame.height)
            let layout = HeroHeader.Layout(headerHeightConstraint: headerHeightConstraint)

            sut.didSetup(layout: layout)
            #expect(sut.headerHeight > configuration.height)
        }

        @Test("didSetup callback provides headerView with correct frame height")
        func didSetup_headerView_frame_height() {
            let configuration = HeroHeader.HeaderViewConfiguration(height: 100)
            let contentView = MockHeader()

            let stubDelegate = StubDelegate()
            let mockController = MockController()
            mockController.headerDelegate = stubDelegate

            try! mockController.configureHeader(.headerView(view: contentView, configuration: configuration))

            #expect(stubDelegate.setupHeaderHeight == configuration.height)
        }
    }
}

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
        print(headerView.frame)
        setupHeaderHeight = headerView.frame.height
    }
}
