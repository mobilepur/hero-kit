import HeroKit
import UIKit

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
            parts.append(config.allowsLineWrap ? "large title (wrap)" : "large title")
        }
        switch smallTitleDisplayMode {
        case .never:
            parts.append("small: never")
        case .always:
            parts.append("small: always")
        case .whenHeaderCollapsed:
            parts.append("small: collapsed")
        case .whenLargeTitleHidden:
            parts.append("small: title hidden")
        }
        return parts.joined(separator: ", ")
    }

}
