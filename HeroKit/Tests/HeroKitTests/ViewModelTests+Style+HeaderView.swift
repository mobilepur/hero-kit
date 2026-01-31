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

    }
}
