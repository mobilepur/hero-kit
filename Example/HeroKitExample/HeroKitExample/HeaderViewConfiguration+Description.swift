import HeroKit
import UIKit

extension HeroHeader.TitleConfiguration {

    var description: String {
        var parts: [String] = []
        if let title {
            parts.append("title: \"\(title)\"")
        }
        if let subtitle = largeSubtitle ?? subtitle {
            parts.append("subtitle: \"\(subtitle)\"")
        }
        return parts.joined(separator: " | ")
    }
}

extension HeroHeader.HeaderViewConfiguration {

    var description: String {
        var parts: [String] = []
        parts.append("h: \(Int(height))")
        if let minHeight {
            parts.append("min: \(Int(minHeight))")
        }
        parts.append(stretches ? "stretch" : "no stretch")
        switch largeTitleDisplayMode {
        case .none:
            break
        case let .belowHeader(config):
            parts.append("below header")
            switch config.smallTitleDisplayMode {
            case .never:
                break
            case .always:
                break
            case .system:
                break // default, don't show
            }
        case let .inline(config):
            parts.append("inline title")
        }
        return parts.joined(separator: ", ")
    }

}
