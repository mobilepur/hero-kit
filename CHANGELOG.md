# Changelog

## 0.1.0

Initial release.

### Features

- **Opaque headers** — colored navigation bars that collapse on scroll, compatible with iOS 26+
- **Header views** — custom views (images, gradients, etc.) as collapsible headers
- **Large titles** — displayed below header or inline as overlay
- **Subtitles** — for both large and inline titles
- **Stretch effect** — elastic overscroll behavior
- **Inline dimming** — solid or gradient overlays for readability on images
- **Dark mode** — `lightModeOnly` option for opaque headers that switch to system appearance in dark mode
- **Delegate callbacks** — scroll state changes (collapse, expand, stretch, content hidden)
- **Programmatic control** — `expandHeader()`, `collapseHeader()`, `collapseHeaderContent()`
- **Title observation** — automatic header updates when `viewController.title` changes
- **Small title modes** — `.system`, `.always`, `.never` for navigation bar title visibility
