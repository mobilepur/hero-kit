# HeroKit

HeroKit provides collapsible navigation headers for UIKit. It was created in response to iOS 26 dropping support for colored navigation bars with large titles.

## Header Styles

### Image Header

```swift
setHeader(
    .image(
        image: .init(url: URL(string: "https://example.com/photo.jpg")!),
        configuration: .init(height: 300),
        title: .init(title: "Explore", largeSubtitle: "Discover new places")
    )
)
```

### Remote Image Header (convenience)

```swift
setImageHeader(
    url: URL(string: "https://example.com/photo.jpg")!,
    configuration: .init(height: 300),
    title: .init(title: "Explore")
)
```

### Custom View Header

```swift
let mapView = MKMapView()
setHeader(
    .headerView(
        view: mapView,
        configuration: .init(height: 250),
        title: .init(title: "Map")
    )
)
```

### Opaque Header

Replicates pre-iOS 26 colored navigation bars.

```swift
setOpaqueHeader(
    title: .init(title: "Tours"),
    backgroundColor: .systemBlue,
    foregroundColor: .white,
    prefersLargeTitles: true
)
```

## Configuration

### HeaderViewConfiguration

| Parameter | Default | Description |
|---|---|---|
| `height` | `200` | Header height in points |
| `minHeight` | `nil` | Minimum height when collapsed (sticky header) |
| `stretches` | `true` | Stretch effect on overscroll |
| `largeTitleDisplayMode` | `.none` | `.none`, `.belowHeader()`, or `.inline()` |

### TitleConfiguration

| Parameter | Default | Description |
|---|---|---|
| `title` | `nil` | Small navigation bar title |
| `subtitle` | `nil` | Small navigation bar subtitle (iOS 26+) |
| `largeTitle` | `nil` | Large title text (falls back to `title`) |
| `largeSubtitle` | `nil` | Large subtitle text (falls back to `subtitle`) |

### Large Title Display Modes

**Below Header** — title appears below the header content:
```swift
.belowHeader(.init(
    allowsLineWrap: true,
    smallTitleDisplayMode: .system,
    accessories: [.init(.button(configuration: .plain(), action: editAction))]
))
```

**Inline** — title overlays the header content with optional dimming:
```swift
.inline(.init(dimming: .gradient))
```

Dimming options: `.none`, `.gradient`, `.complete`

## Programmatic Control

```swift
expandHeader(animated: true)          // Fully expand
collapseHeaderContent(animated: true)  // Hide content, keep large title
collapseHeader(animated: true)         // Fully collapse to nav bar only
```

## Delegate

Set the delegate before or after calling `setHeader()`:

```swift
headerDelegate = self
```

All callbacks are optional:

```swift
extension MyController: HeroHeaderDelegate {
    func heroHeader(_ controller: UIViewController, didSetup headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didScroll headerView: HeroHeaderView, offset: CGFloat) { }
    func heroHeader(_ controller: UIViewController, didStretch headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didUnstretch headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didCollapseHeaderContent headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didCollapse headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didBecameVisible headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, headerContentDidBecameVisible headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didExpandFully headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didShowLargeTitle headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didShowSmallTitle headerView: HeroHeaderView) { }
    func heroHeader(_ controller: UIViewController, didUpdateTitle headerView: HeroHeaderView, title: String) { }
}
```

### Header States

| State | Description |
|---|---|
| `stretched` | Overscroll — header is stretched beyond rest position |
| `fullyExpanded` | Default rest position — header fully visible |
| `expanded` | Header visible but partially collapsed |
| `contentHidden` | Content behind nav bar, large title still visible |
| `collapsed` | Fully collapsed — only navigation bar visible |

## Navigation Bar Restoration

When navigating between controllers with different header styles (e.g. image header -> opaque modal), the navigation bar appearance can get out of sync on return.

HeroKit handles this automatically via the **`restoresOnAppear`** parameter (default `true`). An invisible sentinel child view controller observes `viewWillAppear` and re-fires the appropriate delegate callback, so your navigation bar styling is restored without rebuilding the header or changing the scroll position.

```swift
// In viewDidLoad — that's all you need:
setHeader(
    .image(
        image: .init(url: imageURL),
        configuration: .init(height: 300),
        title: .init(title: "Detail")
    )
)
// restoresOnAppear defaults to true.
// On every subsequent viewWillAppear, the delegate is re-notified
// with the current state (e.g. didCollapse, headerContentDidBecameVisible).
```

### How it works

1. `setHeader()` installs a hidden child VC that mirrors the parent's appearance lifecycle
2. On the first `viewWillAppear` (initial setup), nothing happens
3. On subsequent appearances (returning from push/modal), `reapplyHeaderStyle()` is called automatically
4. This re-fires the delegate callback matching the current scroll state
5. Your delegate sets the correct navigation bar style — no scroll jump, no header rebuild

### Example: Switching between transparent and opaque

```swift
class TourDetailController: UICollectionViewController, HeroHeaderDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        headerDelegate = self
        setHeader(
            .image(
                image: .init(url: tourImageURL),
                configuration: .init(height: 300),
                title: .init(title: tour.name)
            )
        )
    }

    // These callbacks fire during scroll AND on viewWillAppear (via restoresOnAppear)
    func heroHeader(_ controller: UIViewController, didCollapseHeaderContent _: HeroHeaderView) {
        navigationController?.configureOpaqueAppearance(backgroundColor: .systemBackground, foregroundColor: nil)
    }

    func heroHeader(_ controller: UIViewController, headerContentDidBecameVisible _: HeroHeaderView) {
        navigationController?.configureTransparentAppearance()
    }
}
```

### Opting out

If a header is temporary or you manage appearance manually:

```swift
setHeader(.image(...), restoresOnAppear: false)
```

You can still trigger restoration manually:

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reapplyHeaderStyle()
}
```

## Matched Transitions

Present a controller with a morph animation from a source element to the destination's header:

```swift
heroPresent(detailVC, source: selectedCell)
```

The source conforms to `HeroTransitionSource`, the destination conforms to `HeroTransitionDestination`. On dismiss, the animation reverses automatically. If the source is no longer available (cell recycled), it falls back to a standard fade.
