# HeroKit

A lightweight UIKit library for collapsible navigation headers on iOS.

HeroKit lets you add image headers, colored bars, or custom views that collapse smoothly on scroll — filling the gap left by iOS 26, which removed support for colored navigation bars with large titles.

<p>
  <img src="docs/images/opaque.gif" width="250" alt="Opaque Header">
  <img src="docs/images/below-header.gif" width="250" alt="Image Header with Large Title">
  <img src="docs/images/inline-title.gif" width="250" alt="Inline Title with Dimming">
  <img src="docs/images/matched-transition.gif" width="250" alt="Matched Transition">
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
- **Matched transitions** — morph a source element into the destination's header
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

        setHeader(
            .image(
                image: .init(url: URL(string: "https://example.com/photo.jpg")!),
                configuration: .init(height: 300),
                title: .init(title: "Explore", largeSubtitle: "Discover new places")
            )
        )
    }
}
```

### Matched Transitions

Present a view controller with a morph animation from a source element to the destination's header:

```swift
heroPresent(detailVC, source: selectedCell)
```

The source conforms to `HeroTransitionSource`. Dismiss reverses the animation automatically.

## License

MIT
