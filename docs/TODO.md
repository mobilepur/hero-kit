# TODO

## Gallery 
- vertical swipes/gestures must be ignored and need to be progagated to the scroll view
- horizontal gestures will scroll the gallery content


## Issues
- Tests are crashing when executed all at once


## Long List
- Gradient in Headers
- SVG in Headers
- ImageURL (online and from bundle with different loading animation types)


## Page Controller

  Neue Datei PageImageController.swift:
  - PageImageView als UIControl-Subklasse (clever - wird von HeroHeaderView.hitTest
   durchgelassen weil hit is UIControl)
  - PageImageController nutzt PageImageView als Root-View via loadView()
  - hitTestingEnabled Flag zum Ein-/Ausschalten

  Neuer GalleryInteractionMode enum:
  - .forwarded = bisheriges Verhalten (Swipe-Gestures auf ScrollView)
  - .native = neuer Modus (UIPageViewController bekommt direkt Touches)

  Was schon verdrahtet ist:
  - GalleryPageController erstellt jetzt PageImageController statt
  generische UIViewController
  - interactionMode wird durchgereicht von API → Config → PageVC
  - Bei .forwarded werden weiterhin die Swipe-Gestures installiert
  - Bei .native wird view.isUserInteractionEnabled = true und hitTestingEnabled =
  true gesetzt

  Was noch fehlt:
  Das Kernstück! Die dynamische Touch-Erkennung in PageImageView. Aktuell ist es
  statisch - entweder alle Touches oder keine. Es fehlt die
  touchesBegan/touchesMoved-Logik, die erkennt ob der User horizontal (→ Gallery
  pagen) oder vertikal (→ ScrollView scrollen) wischt, und dann den HitTest
  entsprechend umschaltet.
