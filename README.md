# HeroKit

A lightweight UIKit library for collapsible navigation headers on iOS.

HeroKit lets you add image headers, colored bars, or custom views that collapse smoothly on scroll — filling the gap left by iOS 26, which removed support for colored navigation bars with large titles.

## Features

- **Image headers** — full-bleed photos that shrink into the navigation bar on scroll
- **Colored opaque headers** — solid-color bars with large title support (pre-iOS 26 style)
- **Custom view headers** — any `UIView` as a collapsible header
- **Large titles** — below the header or inline (overlaid on the header image)
- **Subtitles** — pair a subtitle with your large title
- **Stretch & bounce** — overscroll pull-down effect
- **Dimming** — gradient or solid overlay for inline titles on busy images
- **Programmatic control** — expand, collapse content, or fully collapse the header
- **Delegate callbacks** — respond to scroll, stretch, collapse, and title visibility changes

## Requirements

- iOS 16+
- Swift 6.2+
- No external dependencies

## Installation

### Swift Package Manager

Add HeroKit as a local package dependency, or point to the repository URL:

```swift
dependencies: [
    .package(path: "path/to/HeroKit")
]
```

## Quick Start

```swift
import HeroKit

class PhotoViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let imageView = UIImageView(image: UIImage(named: "landscape"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        try? setHeader(.headerView(
            view: imageView,
            configuration: .init(height: 300),
            title: .init(title: "Explore", largeSubtitle: "Discover new places")
        ))
    }
}
```

## Header Styles

### Image / Custom View Header

```swift
// Large title below the header image
try setHeader(.headerView(
    view: imageView,
    configuration: .init(
        height: 300,
        stretches: true,
        largeTitleDisplayMode: .belowHeader()
    ),
    title: .init(title: "Ancient Ruins", largeSubtitle: "Lost in time")
))

// Inline title overlaid on the image with gradient dimming
try setHeader(.headerView(
    view: imageView,
    configuration: .init(
        height: 300,
        largeTitleDisplayMode: .inline(.init(dimming: .gradient))
    ),
    title: .init(title: "Sacred Temple", largeSubtitle: "Kyoto, Japan")
))
```

### Colored Opaque Header

```swift
try setHeader(.opaque(
    title: .init(title: "Settings"),
    backgroundColor: .systemMint,
    foregroundColor: .black,
    prefersLargeTitles: true
))
```

## Configuration

### HeaderViewConfiguration

| Property | Default | Description |
|---|---|---|
| `height` | `200` | Header content height |
| `minHeight` | `nil` | Minimum height when collapsed |
| `stretches` | `true` | Enable overscroll stretch effect |
| `largeTitleDisplayMode` | `.none` | `.none`, `.belowHeader()`, or `.inline()` |

### LargeTitleDisplayMode

- **`.none`** — no large title
- **`.belowHeader()`** — title sits below the header content, supports `allowsLineWrap` and `smallTitleDisplayMode`
- **`.inline()`** — title overlays the header, supports dimming (`.none`, `.gradient`, `.complete`)

### TitleConfiguration

```swift
TitleConfiguration(
    title: "Nav Bar Title",       // small title in navigation bar
    subtitle: "Small subtitle",   // small subtitle (iOS 26+)
    largeTitle: "Big Title",      // large title (falls back to title)
    largeSubtitle: "Details"      // large subtitle
)
```

## Programmatic Control

```swift
// Expand header to full height
expandHeader(animated: true)

// Collapse just the content, keep large title visible
collapseHeaderContent(animated: true)

// Fully collapse into the navigation bar
collapseHeader(animated: true)
```

## Delegate

Conform to `HeroHeaderDelegate` for fine-grained scroll and visibility callbacks:

```swift
controller.headerDelegate = self

func heroHeader(_ controller: UIViewController, didScroll headerView: HeroHeaderView, offset: CGFloat) {
    // called on every scroll frame
}

func heroHeader(_ controller: UIViewController, didCollapseHeaderContent headerView: HeroHeaderView) {
    // header content scrolled behind the navigation bar
}

func heroHeader(_ controller: UIViewController, didShowLargeTitle headerView: HeroHeaderView) {
    // large title became visible
}
```

## License

MIT
