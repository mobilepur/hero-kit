# HeroKit

A lightweight UIKit library for collapsible navigation headers on iOS.

HeroKit lets you add image headers, colored bars, or custom views that collapse smoothly on scroll — filling the gap left by iOS 26, which removed support for colored navigation bars with large titles.

<p>
  <img src="docs/images/opaque.gif" width="250" alt="Opaque Header">
  <img src="docs/images/below-header.gif" width="250" alt="Image Header with Large Title">
  <img src="docs/images/inline-title.gif" width="250" alt="Inline Title with Dimming">
</p>

## Features

- **Image headers** — full-bleed photos that shrink into the navigation bar on scroll
- **Remote image headers** — load images from URLs with a loading spinner
- **Colored opaque headers** — solid-color bars with large title support (pre-iOS 26 style)
- **Custom view headers** — any `UIView` as a collapsible header
- **Large titles** — below the header or inline (overlaid on the header image)
- **Subtitles** — pair a subtitle with your large title
- **Stretch & bounce** — overscroll pull-down effect
- **Dimming** — gradient or solid overlay for inline titles on busy images
- **Programmatic control** — expand, collapse content, or fully collapse the header
- **Delegate callbacks** — respond to scroll, stretch, collapse, and title visibility changes

## Requirements

- iOS 17+
- Swift 6.2+
- No external dependencies

## Installation

### Swift Package Manager

Add HeroKit via **File > Add Package Dependencies...** in Xcode with:

```
https://github.com/mobilepur/hero-kit
```

Or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mobilepur/hero-kit", from: "0.1.2")
]
```

## Quick Start

```swift
import HeroKit

class PhotoViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Or use the convenience method: try? setImageHeader(url:configuration:title:)
        try? setHeader(
            .image(
                image: .init(url: URL(string: "https://example.com/photo.jpg")!),
                configuration: .init(height: 300),
                title: .init(title: "Explore", largeSubtitle: "Discover new places")
            )
        )
    }
}
```

## Header Styles

### Image / Custom View Header

```swift
// Large title below the header image — or use: try setHeader(view:configuration:title:)
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

### Remote Image Header

```swift
// Or use the convenience method: try setImageHeader(url:contentMode:backgroundColor:configuration:title:)
try setHeader(
    .image(
        image: .init(
            url: URL(string: "https://example.com/photo.jpg")!,
            contentMode: .scaleAspectFit,
            backgroundColor: .secondarySystemBackground
        ),
        configuration: .init(height: 300),
        title: .init(title: "Remote Landscape")
    )
)
```

### Colored Opaque Header

```swift
// Or use the convenience method: try setOpaqueHeader(title:backgroundColor:foregroundColor:prefersLargeTitles:)
try setHeader(
    .opaque(
        title: .init(title: "Settings"),
        backgroundColor: .systemMint,
        foregroundColor: .black,
        prefersLargeTitles: true
    )
)
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
