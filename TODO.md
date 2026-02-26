# Feature: reapplyHeaderStyle() API

## Problem

Wenn ein UIViewController mit HeroKit-Header (z.B. `.image` oder `.opaque` mit Large Titles) einen anderen Controller pushed/presented und dieser einen anderen NavigationBar-Style setzt, bleibt beim Zurücknavigieren der falsche Style hängen.

**Beispiel-Flow:**
1. `TourDetail.Controller` hat einen `.image`-Header → NavigationBar ist transparent (`.style(.image)`)
2. User öffnet `SightDetail` (modal) → NavigationBar wird `.opaque`
3. User dismisst `SightDetail` → `TourDetail` erscheint wieder, aber die NavigationBar hat noch den `.opaque` Style von SightDetail

Das gleiche Problem tritt auf bei:
- `TourList.Controller` (`.opaque` mit Large Titles) → Push zu `TourMap` → Zurück
- `Discover.Container` (transparent/opaque je nach View-Mode) → Modal SightDetail → Zurück

## Gewünschte Lösung

Eine leichtgewichtige `reapplyHeaderStyle()` Methode auf `UIViewController`, die Controller in `viewWillAppear` oder `viewDidAppear` aufrufen können, um den korrekten NavigationBar-Style wiederherzustellen.

### Anforderungen

1. **Kein Header-Neuaufbau**: Die Methode darf `cleanupExistingHeader()` NICHT aufrufen. Der Header (HeaderView, ScrollView-Subscription, ViewModel) bleibt komplett intakt.
2. **Kein Scroll-Position-Sprung**: ContentInsets und ContentOffset dürfen nicht verändert werden.
3. **Delegate re-notifizieren**: Der `HeroHeaderDelegate` soll über den aktuellen `State` informiert werden, damit der Controller seinen NavigationBar-Style korrekt setzen kann.
4. **Funktioniert für alle Header-Styles**: `.image`, `.headerView`, `.opaque` (mit und ohne Large Titles).

### Vorgeschlagene Implementierung

**`HeroKit+API.swift`** — Neue public API:
```swift
/// Re-notifies the delegate about the current header state.
/// Use in viewWillAppear/viewDidAppear to restore navigation bar styling
/// after returning from another controller.
///
/// This is lightweight — it does NOT rebuild the header or modify scroll position.
/// It only re-fires the appropriate delegate callback based on the current state.
func reapplyHeaderStyle() {
    viewModel?.reapplyState()
}
```

**`HeroHeader+ViewModel.swift`** — Neue interne Methode:
```swift
func reapplyState() {
    guard let controller, let headerView else { return }
    switch state {
    case .collapsed:
        delegate?.heroHeader(controller, didCollapse: headerView)
    case .contentHidden:
        delegate?.heroHeader(controller, didCollapseHeaderContent: headerView)
    case .expanded, .fullyExpanded:
        delegate?.heroHeader(controller, headerContentDidBecameVisible: headerView)
    case .stretched:
        delegate?.heroHeader(controller, didStretch: headerView)
    }
}
```

### Wie der Consumer es nutzt

```swift
// TourDetail.Controller
extension TourDetail.Controller: HeroHeaderDelegate {
    func heroHeader(_: UIViewController, didCollapseHeaderContent _: HeroHeaderView) {
        navigationController?.style(.opaque)
    }

    func heroHeader(_: UIViewController, headerContentDidBecameVisible _: HeroHeaderView) {
        navigationController?.style(.image)
    }
}

// In viewWillAppear:
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reapplyHeaderStyle() // re-fires didCollapseHeaderContent or headerContentDidBecameVisible
}
```

### Edge Case: Kein HeroKit-Header vorhanden

Wenn `viewModel` nil ist (Controller hat keinen HeroKit-Header, z.B. `.opaque` ohne Large Titles auf < iOS 26), ist `reapplyHeaderStyle()` ein No-Op. Das ist korrekt — solche Controller können stattdessen direkt `navigationController?.style(...)` in `viewWillAppear` aufrufen.

## Betroffene Dateien

| Datei | Änderung |
|---|---|
| `Sources/HeroKit/HeroKit+API.swift` | Neue `reapplyHeaderStyle()` public extension method |
| `Sources/HeroKit/HeroHeader+ViewModel.swift` | Neue `reapplyState()` Methode |

## Tests

- Unit-Test: ViewModel im `.collapsed` State → `reapplyState()` → Delegate erhält `didCollapse`
- Unit-Test: ViewModel im `.expanded` State → `reapplyState()` → Delegate erhält `headerContentDidBecameVisible`
- Unit-Test: ViewModel ohne Header (nil) → `reapplyState()` → kein Crash, kein Delegate-Call
