# HeroKit

Collapsible navigation headers for UIKit. Colored bars, images, or custom views that collapse on scroll — with large title support.

Built as a response to iOS 26 removing support for colored navigation bars with large titles.

## Features

- Colored opaque headers that collapse like pre-iOS 26 navigation bars
- Image or custom view headers with scroll-to-collapse
- Large titles (below header or inline overlay)
- Subtitle support for large and small titles
- Stretch effect on overscroll
- Dark mode support with `lightModeOnly` option
- Dimming overlays (solid or gradient) for inline titles
- Delegate callbacks for scroll state changes

## Requirements

- iOS 16+
- Swift 6.2+

## Installation

Add HeroKit as a Swift Package dependency:

```
https://github.com/mobilepur/hero-kit.git
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mobilepur/hero-kit.git", from: "0.1.0")
]
```

## Usage

### Opaque Header (colored navigation bar)

```swift
try setHeader(.opaque(
    title: .init(title: "Colors"),
    backgroundColor: .systemBlue,
    foregroundColor: .white,
    prefersLargeTitles: true
))
```

### Header View (image or custom view)

```swift
let imageView = UIImageView(image: UIImage(named: "hero"))
imageView.contentMode = .scaleAspectFill

try setHeader(.headerView(
    view: imageView,
    configuration: .init(
        height: 300,
        stretches: true,
        largeTitleDisplayMode: .inline(.init(dimming: .gradient))
    ),
    title: .init(title: "Adventure")
))
```

### Large Title Below Header

```swift
try setHeader(.headerView(
    view: myView,
    configuration: .init(
        height: 200,
        largeTitleDisplayMode: .belowHeader(.init(allowsLineWrap: true))
    ),
    title: .init(title: "Long Title That Wraps")
))
```

### Delegate

```swift
class MyController: UIViewController, HeroHeaderDelegate {
    func viewDidLoad() {
        super.viewDidLoad()
        headerDelegate = self
    }

    func heroHeader(_ controller: UIViewController, didCollapse headerView: HeroHeaderView) {
        // Header fully collapsed
    }

    func heroHeader(_ controller: UIViewController, didExpandFully headerView: HeroHeaderView) {
        // Header back to full size
    }
}
```

### Programmatic Control

```swift
expandHeader()              // Scroll to fully expanded
collapseHeaderContent()     // Hide content, keep large title
collapseHeader()            // Fully collapse to nav bar
```

## Roadmap

- Attributed title support for large titles
- Gradient backgrounds for headers
- SVG support in headers
- Image URL loading (remote + bundle) with loading animations

## Known Issues

- Navigating back to an opaque header may not restore colors
- Switching to "Light Mode Only" can cause the header to disappear

## License

MIT
