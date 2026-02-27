## Issues 


### Small Header wrong color when popping from nav stack
1. Open Example
2. open Opaque Header with white small header -> shows small header in white
3. open Image Header -> shows small header in black
4- go back -> collaps header -> shows small header in black

**Ursache:** `setupLargeTitleOpaqueHeaderCompatibleMode` erstellt einen `.headerView`-Style und speichert diesen im ViewModel statt des originalen `.opaque`-Styles. Dadurch greift der `.opaque`-Check in `reapplyState()` nicht und die foregroundColor wird beim Zurückkehren nicht wiederhergestellt.

**Lösung — ViewModel immer mit Original-Style:**
1. `setHeader()` erstellt immer zuerst den ViewModel mit dem Original-Style
2. `setupHeaderView` erstellt keinen ViewModel mehr, sondern nutzt den bestehenden
3. `setupHeaderView` bekommt Configuration als Parameter (statt aus dem Style zu lesen), weil `.opaque` kein `headerViewConfiguration` hat
4. `setupLargeTitleOpaqueHeaderCompatibleMode` erstellt keinen neuen Style mehr, sondern ruft `setupHeaderView` direkt mit der berechneten Config auf
5. `reapplyState()` hat immer den echten Style → `.opaque`-Check funktioniert

**Außerdem:**
- Syntaxfehler in `UINavigationBarAppearance+Helper.swift:78`: `@available(iOS 26, *)x` → stray `x` entfernen
- Debug-`print`-Statements entfernen

### Breaking constraints in Image Header
Unable to simultaneously satisfy constraints.
    Probably at least one of the constraints in the following list is one you don't want. 
    Try this: 
        (1) look at each constraint and try to figure out which you don't expect; 
        (2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x600002148050 V:|-(0)-[UIImageView:0x105c42410]   (active, names: '|':UIView:0x105c1f850 )>",
    "<NSLayoutConstraint:0x60000214aa30 UIImageView:0x105c42410.bottom == UIView:0x105c1f850.bottom   (active)>",
    "<NSLayoutConstraint:0x6000021488c0 UIImageView:0x105c42410.height == 200   (active)>",
    "<NSLayoutConstraint:0x600002158230 'UIView-Encapsulated-Layout-Height' UIView:0x105c1f850.height == 220   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x6000021488c0 UIImageView:0x105c42410.height == 200   (active)>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
