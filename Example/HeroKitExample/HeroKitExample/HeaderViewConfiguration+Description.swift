import HeroKit
import UIKit

extension HeroHeader.HeaderViewConfiguration {

    var description: String {
        var parts: [String] = []
        parts.append("h: \(Int(height))")
        if let minHeight {
            parts.append("min: \(Int(minHeight))")
        }
        if !bounces {
            parts.append("no bounce")
        }
        return parts.joined(separator: ", ")
    }

}
