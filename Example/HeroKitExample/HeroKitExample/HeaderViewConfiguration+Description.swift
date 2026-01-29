import HeroKit
import UIKit

extension HeroHeader.HeaderViewConfiguration {

    var description: String {
        var parts: [String] = []
        parts.append("h: \(Int(height))")
        if let minHeight {
            parts.append("min: \(Int(minHeight))")
        }
        if !stretches {
            parts.append("no stretch")
        }
        switch largeTitleDisplayMode {
        case .none:
            break
        case let .belowHeader(config):
            parts.append(config.allowsLineWrap ? "large title (wrap)" : "large title")
        }
        return parts.joined(separator: ", ")
    }

}
