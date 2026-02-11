@testable import HeroKit
import Testing
import UIKit

@Suite("LargeTitleView Sizing")
@MainActor
struct LargeTitleViewSizingTests {

    private let width: CGFloat = 375

    private func measureHeight(_ view: LargeTitleView) -> CGFloat {
        let targetSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height
        )
        return view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    // MARK: - Baseline

    @Test("Single-line title has non-zero height")
    func singleLineTitle_hasHeight() {
        let view = LargeTitleView(title: "Hello", fog: false)
        let height = measureHeight(view)
        #expect(height > 0)
    }

    // MARK: - Subtitle

    @Test("Title with subtitle is taller than title alone")
    func subtitle_increaseHeight() {
        let titleOnly = LargeTitleView(title: "Hello", fog: false)
        let withSubtitle = LargeTitleView(title: "Hello", subtitle: "World", fog: false)

        let titleHeight = measureHeight(titleOnly)
        let subtitleHeight = measureHeight(withSubtitle)

        #expect(subtitleHeight > titleHeight)
    }

    // MARK: - Line Wrap

    @Test("Long title with line wrap is taller than single-line")
    func lineWrap_increasesHeight() {
        let longTitle = String(repeating: "Title ", count: 20)
        let singleLine = LargeTitleView(title: longTitle, allowsLineWrap: false, fog: false)
        let multiLine = LargeTitleView(title: longTitle, allowsLineWrap: true, fog: false)

        let singleHeight = measureHeight(singleLine)
        let multiHeight = measureHeight(multiLine)

        #expect(multiHeight > singleHeight)
    }

    // MARK: - Combined

    @Test("Subtitle + line wrap is taller than subtitle alone")
    func subtitleAndLineWrap_tallest() {
        let longTitle = String(repeating: "Title ", count: 20)
        let subtitleOnly = LargeTitleView(title: longTitle, subtitle: "Sub", fog: false)
        let subtitleAndWrap = LargeTitleView(
            title: longTitle,
            subtitle: "Sub",
            allowsLineWrap: true,
            fog: false
        )

        let subtitleHeight = measureHeight(subtitleOnly)
        let combinedHeight = measureHeight(subtitleAndWrap)

        #expect(combinedHeight > subtitleHeight)
    }

    // MARK: - Consistency

    @Test("Same config produces same height")
    func sameConfig_sameHeight() {
        let a = LargeTitleView(title: "Test", subtitle: "Sub", fog: false)
        let b = LargeTitleView(title: "Test", subtitle: "Sub", fog: false)

        #expect(measureHeight(a) == measureHeight(b))
    }

    @Test("Fog does not affect height")
    func fog_doesNotAffectHeight() {
        let withFog = LargeTitleView(title: "Test", fog: true)
        let withoutFog = LargeTitleView(title: "Test", fog: false)

        #expect(measureHeight(withFog) == measureHeight(withoutFog))
    }
}
