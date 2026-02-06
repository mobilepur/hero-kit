# TODO

- Subtitle support
    - iOS 26+ native APIs:
        - `navigationItem.subtitle` / `attributedSubtitle` / `subtitleView`
        - `navigationItem.largeSubtitle` / `largeAttributedSubtitle` / `largeSubtitleView`
        - `UINavigationBarAppearance.subtitleTextAttributes` / `largeSubtitleTextAttributes`
    - Pre-iOS 26: Add subtitle label to `LargeTitleView`
    - HeroKit already uses workaround for iOS 26 Large Titles (Liquid Glass), so implement subtitle consistently in `LargeTitleView`
    - References:
        - https://sebvidal.com/blog/whats-new-in-uikit-26/
        - https://developer.apple.com/documentation/uikit/uinavigationitem/largesubtitleview
- AttributedTitle in LargeTitles support
- Add tests

## Done

- Delegate Method didShowSmallTitle
- Delegate Method didShowLargeTitle
- Darkmode support (lightModeOnly option for opaque headers)
- HeroKit observes title changes and applies them automatically

