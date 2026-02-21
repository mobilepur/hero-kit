# TODO

- ~~make setHeader non-throwing. Instead generate purple warning~~
- make SearchBars working with HeroKit


## Issues:
- Navigating back to opaque-header wont show colors
- Tests are crashing when exectuted all at once
- Switch to "Light Mode only" will make header disappear


## Long List
- Gradient in Headers
- SVG in Headers
- ImageURL (online and from bundle with different loading animation typels)


---

# HeroKit Matched Transition

Eine matched-element Transition, damit z.B. ein Zellen-Thumbnail nahtlos in einen Header morphen kann.

## Übersicht

Es werden 5 neue Dateien unter `Sources/HeroKit/Transition/` angelegt. Anschließend wird die Transition im Example-Projekt demonstriert: Tap auf eine Image-Zelle → Thumbnail morpht in den Header des Detail-Controllers.

---

## Was gebaut werden muss

### 1. Protokoll: `HeroTransitionSource`

**Datei:** `Sources/HeroKit/Transition/HeroTransitionSource.swift`

Wird von der Source-View (z.B. einer CollectionViewCell) implementiert.

```swift
import UIKit

@MainActor
public protocol HeroTransitionSource: AnyObject {
    /// The image view whose content will be animated to the destination
    func heroSourceImageView() -> UIImageView?
    /// The frame in window coordinates for the starting position
    func heroSourceFrame(in window: UIWindow) -> CGRect
    /// Corner radius of the source view (for animating to destination)
    func heroSourceCornerRadius() -> CGFloat
}
```

**Design-Entscheidungen:**
- `AnyObject`-Constraint damit Consumer `weak`-Referenzen halten können (wichtig für Cell-Reuse)
- `@MainActor` passend zum bestehenden HeroKit-Pattern (siehe `HeroHeaderDelegate`)
- `UIImageView` statt `UIImage`, damit der Animator den gerenderten Zustand snapshotten kann

### 2. Protokoll: `HeroTransitionDestination`

**Datei:** `Sources/HeroKit/Transition/HeroTransitionDestination.swift`

Wird vom Destination-ViewController implementiert.

```swift
import UIKit

@MainActor
public protocol HeroTransitionDestination: AnyObject {
    /// The image view that receives the animated image
    func heroDestinationImageView() -> UIImageView?
    /// The target frame in window coordinates
    func heroDestinationFrame(in window: UIWindow) -> CGRect
    /// Corner radius of the destination view
    func heroDestinationCornerRadius() -> CGFloat
}
```

### 3. `HeroMatchedTransition` (Animator)

**Datei:** `Sources/HeroKit/Transition/HeroMatchedTransition.swift`

Custom `UIViewControllerAnimatedTransitioning`. Bekommt `source: HeroTransitionSource` im init.

```swift
import UIKit

@MainActor
public class HeroMatchedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    public let duration: TimeInterval
    public let isPresenting: Bool
    public weak var source: (any HeroTransitionSource)?

    public init(source: any HeroTransitionSource, duration: TimeInterval = 0.4, isPresenting: Bool)
}
```

**Destination finden:** Der Animator sucht rekursiv in der VC-Hierarchie des `toVC` (bzw. `fromVC` beim Dismiss) nach einem `HeroTransitionDestination`-Conformer:

```swift
private func findDestination(from viewController: UIViewController) -> (any HeroTransitionDestination)? {
    if let dest = viewController as? HeroTransitionDestination { return dest }
    if let nav = viewController as? UINavigationController {
        return nav.topViewController.flatMap { findDestination(from: $0) }
    }
    for child in viewController.children {
        if let dest = findDestination(from: child) { return dest }
    }
    return nil
}
```

**Present-Animation:**
1. `toVC.view` zu `containerView` hinzufügen, `layoutIfNeeded()` erzwingen, `toVC.view.alpha = 0`
2. Snapshot-`UIImageView` aus Source-Image erstellen (`.scaleAspectFill`, `clipsToBounds = true`)
3. Snapshot an `sourceFrame` positionieren mit `sourceCornerRadius`
4. Source- und Destination-ImageViews temporär ausblenden (`.isHidden = true`)
5. Snapshot zu `containerView` hinzufügen
6. `UIView.animate` mit Spring-Damping (~0.85):
   - Snapshot frame → `destinationFrame`
   - Snapshot `layer.cornerRadius` → `destinationCornerRadius`
   - `toVC.view.alpha` → 1.0
7. Completion:
   - Snapshot entfernen
   - Destination-ImageView wieder einblenden
   - Source-ImageView wieder einblenden
   - `transitionContext.completeTransition(!transitionContext.transitionWasCancelled)`

**Dismiss-Animation:**
1. Snapshot vom Destination-ImageView erstellen, an `destinationFrame` positionieren
2. Source- und Destination-ImageViews ausblenden
3. `UIView.animate` mit Spring:
   - Snapshot → `sourceFrame`
   - `layer.cornerRadius` → `sourceCornerRadius`
   - `fromVC.view.alpha` → 0
4. Completion: Snapshot entfernen, Source-ImageView einblenden, `completeTransition()`

**Fallback:** Wenn `source` nil ist (Cell recycled, weak reference weg), einfacher Fade-Out ohne Snapshot.

### 4. `HeroMatchedTransitionDelegate`

**Datei:** `Sources/HeroKit/Transition/HeroMatchedTransitionDelegate.swift`

Convenience `UIViewControllerTransitioningDelegate` der den Animator liefert.

```swift
import UIKit

@MainActor
public class HeroMatchedTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public weak var source: (any HeroTransitionSource)?

    public init(source: any HeroTransitionSource) {
        self.source = source
        super.init()
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let source = self.source else { return nil }
        return HeroMatchedTransition(source: source, isPresenting: true)
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let source = self.source else { return nil }
        return HeroMatchedTransition(source: source, isPresenting: false)
    }
}
```

Gibt `nil` zurück wenn Source weg → System fällt auf Default-Transition zurück.

### 5. `UIViewController+HeroTransition` (Convenience)

**Datei:** `Sources/HeroKit/Extensions/UIViewController+HeroTransition.swift`

```swift
import UIKit
import ObjectiveC

extension UIViewController {
    public func heroPresent(
        _ destination: UIViewController,
        source: any HeroTransitionSource,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let transitionDelegate = HeroMatchedTransitionDelegate(source: source)
        destination.heroTransitionDelegate = transitionDelegate  // retain via associated object
        destination.transitioningDelegate = transitionDelegate
        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: animated, completion: completion)
    }
}

// MARK: - Associated Object Storage

private extension UIViewController {
    enum HeroTransitionKeys {
        nonisolated(unsafe) static var transitionDelegate: Void?
    }

    var heroTransitionDelegate: HeroMatchedTransitionDelegate? {
        get {
            objc_getAssociatedObject(self, &HeroTransitionKeys.transitionDelegate)
                as? HeroMatchedTransitionDelegate
        }
        set {
            objc_setAssociatedObject(
                self, &HeroTransitionKeys.transitionDelegate,
                newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
```

**Wichtig:** `transitioningDelegate` auf `UIViewController` ist `weak`. Ohne den Associated-Object-Trick würde der Delegate sofort deallociert. Das Pattern wird bereits in HeroKit genutzt (siehe `HeroKit+API.swift` Zeilen 402–419 für ViewModel-Storage).

---

## Example-Projekt: Matched Transition Demo

### Ziel

Im bestehenden Example-Projekt (`Example/HeroKitExample/`) soll beim Tap auf eine Image-Zelle (z.B. "City Ride") eine matched transition stattfinden: Das Zellen-Thumbnail morpht in den Header des neuen `HeaderPickerController`.

### Bestehendes Setup

- `HeaderPickerController` zeigt eine CollectionView mit 3 Sektionen (Colors, Views, Image URLs)
- Zellen in "Views" und "Image URLs" haben ein Thumbnail-Image
- Bei Tap wird ein neuer `HeaderPickerController` per Push angezeigt
- Der neue Controller hat den ausgewählten Header-Style

### Änderungen

#### A. Demo-Cell `HeroTransitionSource` Conformance

In `HeaderPickerController.swift` eine der Cell-Registrations (z.B. die Image-Zellen) um eine `HeroTransitionSource`-Conformance erweitern. Die Zelle braucht Zugriff auf ihr `UIImageView`.

Option: Eigene `ImageCell: UICollectionViewCell` anlegen (statt `UICollectionViewListCell`), die `HeroTransitionSource` konformt.

Oder: Die vorhandene Zelle wrappen — der einfachste Weg ist, die Zelle in `collectionView(_:didSelectItemAt:)` als Source zu benutzen, wenn sie ein Bild hat.

#### B. Neuer Detail-Controller als Destination

Statt Push einen **modalen** `HeaderPickerController` präsentieren (wrapped in `UINavigationController`). Der `HeaderPickerController` konformt zu `HeroTransitionDestination` und liefert das Header-ImageView.

Alternativ: Einen einfachen `DetailViewController` anlegen, der nur einen großen Image-Header zeigt und `HeroTransitionDestination` implementiert.

#### C. Aufruf in `AppComposer`

In `AppComposer.headerPicker(_:didSelectContent:)`:

```swift
// Für Image-Content: matched transition statt push
if content.isVisualHeader, let cell = sourceCell {
    let detail = makeDetailController(content: content)
    let nav = UINavigationController(rootViewController: detail)
    rootController.heroPresent(nav, source: cell)
} else {
    // Für Colors: normaler push wie bisher
    navigationController.pushViewController(next, animated: true)
}
```

#### D. Dismiss

Close-Button im modalen Controller ruft `dismiss(animated: true)` → der `HeroMatchedTransitionDelegate` liefert den Dismiss-Animator automatisch.

### Verification im Example

1. App starten
2. Tap auf ein Bild in "Views" oder "Image URLs"
3. Thumbnail morpht in den Header des Detail-Controllers
4. Close-Button → Bild morpht zurück in die Zelle
5. Schnell scrollen während Detail offen → Dismiss macht Fade statt Crash

---

## Dateien-Übersicht

### Neue Dateien in HeroKit
```
Sources/HeroKit/
├── Transition/
│   ├── HeroTransitionSource.swift
│   ├── HeroTransitionDestination.swift
│   ├── HeroMatchedTransition.swift
│   └── HeroMatchedTransitionDelegate.swift
└── Extensions/
    └── UIViewController+HeroTransition.swift
```

### Geänderte Dateien im Example
```
Example/HeroKitExample/HeroKitExample/
├── AppComposer.swift                  (matched presentation statt push)
├── HeaderPickerController.swift       (Cell als Source, Destination-Conformance)
```

---

## Spätere Integration in fh-portrait

Sobald die Transition im Example funktioniert, wird sie in fh-portrait integriert:

1. `MapDrawer.CarouselCell` → `HeroTransitionSource` (imageView, frame, cornerRadius 12)
2. `SightDetail.Container` → `HeroTransitionDestination` (BlurImageView im GalleryHeader)
3. Source-Referenz durch die Delegate-Kette fädeln (7 Delegate-Signaturen erweitern um `transitionSource` Parameter)
4. `showSightDetailContainer()` → `heroPresent()` statt `present()`

Details dazu siehe Abschnitt "Integration in fh-portrait" weiter unten.

### Delegate-Kette in fh-portrait

Die CarouselCell-Referenz muss vom Tap bis zur Presentation durchgereicht werden:

| # | Datei | Änderung |
|---|---|---|
| 1 | `MapDrawerPageControllerDelegate.swift` | `mapDrawer(_:didSelectDetailOf:transitionSource:)` |
| 2 | `MapDrawer+PageController.swift` | Cell in `didSelectItemAt` mitgeben, `handleThumbnailTap(marker:source:)` |
| 3 | `TourMapControllerDelegate.swift` | `tourMap(_:didSelectSight:tour:transitionSource:)` |
| 4 | `TourMap+MapController.swift` | Weiterleiten in `mapDrawer(didSelectDetailOf:)` und `drawerDidSwipeUp` |
| 5 | `TourMapContainerDelegate.swift` | `tourMap(_:showSightDetail:tour:animated:transitionSource:)` |
| 6 | `TourMap+Container.swift` | Forwarden in `TourMapControllerDelegate`-Conformance |
| 7 | `Composition+Root+TourMapContainerDelegate.swift` | Source an `showSightDetailContainer` weiterreichen |

Für Swipe-Up braucht `MapDrawer.PageController` eine neue Methode:
```swift
func visibleCarouselCell() -> CarouselCell? {
    guard let index = centeredIndex else { return nil }
    return collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? CarouselCell
}
```

In `Composition+Root+SightDetailDelegate.swift` (`showSightDetailContainer`):
```swift
func showSightDetailContainer(
    sight: Sight, tour: Tour?, sender: UIViewController,
    isModal: Bool = true,
    transitionSource: (any HeroTransitionSource)? = nil,  // NEU
    onSightUpdate: ((Sight) -> Void)?
) {
    // ... bestehender Code ...
    if isModal {
        let nav = FutureNavigationController(rootViewController: container, ...)
        if let transitionSource {
            sender.heroPresent(nav, source: transitionSource)
        } else {
            nav.modalPresentationStyle = .fullScreen
            sender.present(nav, animated: true)
        }
    }
}
```

Alle anderen Aufrufer von `showSightDetailContainer` bleiben unverändert (Parameter hat default `nil`).








