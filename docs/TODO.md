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


## Subtitle

We added a TitleConfiguration
- The titles and subtitles should be set according to that title configuration
- Add examples in example project
- Subtitle should be a lighter version of the foregroundColor, for example: label -> secondaryLabel
- If prefersLargeTitles is set and no largeTitle or largeSubtitle is specified, we will use the title/subtitle
- Add a subtitle to the largeTitleView
- Add a purple system warning in xcode when largeTitles or largeSubtitles are directly specified in the viewController





For iOS 26:
- set subtitle as small title if specified:
Older versions:
- we don't set a small title 

## Issues:
- Make some headerViews self sizing
- Navigating back to opaque-header wont show colors
- Tests are crashing when exectuted all at once
- Switch to "Light Mode only" will make header disappear

### Self Sizing Issue:
- ~~Opaque-Style with large title uses inline large titles -> the height of the header in that case should depend on the largeHeaderView.~~
~~NavBar (fixed height) + largeHeaderView (depends on font, subtitle etc)~~ ✅ Done: measures LargeTitleView dynamically via `measureInlineTitleHeight`
- HeaderView-Style - below large titles -> the headerView should have a fixed size, the largeHeaderView height should depend on the label/subtitles.
- HeaderView-Style - inline large headers -> the height is predefined, the user has the responsible to give enought size, that the large title fits.




## Long List
- Gradient in Headers
- SVG in Headers
- ImageURL (online and from bundle with different loading animation typels)








