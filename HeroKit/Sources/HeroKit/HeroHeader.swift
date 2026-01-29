import UIKit

public enum HeroHeader {
    // MARK: - Header Style

    public enum Style {
        case color(backgroundColor: UIColor, foregroundColor: UIColor?)
    }

    public enum Error: Swift.Error {
        case scrollViewNotFound
        case navigationControllerNotFound
    }
}
