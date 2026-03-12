# TODO

## Gallery

### Expose current image view via delegate

Add a new `HeroHeaderDelegate` method that provides the currently displayed `UIImageView`:

```swift
func heroHeader(
    _ controller: UIViewController,
    galleryDidDisplayImageView imageView: UIImageView,
    in gallery: GalleryController,
    headerView: HeroHeaderView
)
```

This should fire:
- When the initial image is first displayed (first load)
- On every page change

This allows `HeroTransitionDestination` consumers to store a weak reference to the current image view and return it from `heroDestinationImageView()` for the matched dismiss animation. Without this, the dismiss transition falls back to a simple fade.
