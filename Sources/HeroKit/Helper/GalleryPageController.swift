import UIKit

final class GalleryPageController: UIPageViewController,
    UIPageViewControllerDataSource
{
    private let urls: [URL]
    private let imageContentMode: UIView.ContentMode
    private let imageBackgroundColor: UIColor?
    private let loadingType: HeroHeader.LoadingType
    private let pageControlConfig: HeroHeader.PageControlConfiguration
    private let interactionMode: HeroHeader.GalleryInteractionMode

    init(
        urls: [URL],
        contentMode: UIView.ContentMode = .scaleAspectFill,
        backgroundColor: UIColor? = nil,
        loadingType: HeroHeader.LoadingType = .spinner,
        pageControl: HeroHeader.PageControlConfiguration = .display(),
        interactionMode: HeroHeader.GalleryInteractionMode = .forwarded
    ) {
        self.urls = urls
        imageContentMode = contentMode
        imageBackgroundColor = backgroundColor
        self.loadingType = loadingType
        pageControlConfig = pageControl
        self.interactionMode = interactionMode
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        updateInteractionMode()
        if let first = makeImageController(at: 0) {
            setViewControllers([first], direction: .forward, animated: false)
        }
        configurePageControl()
    }

    private func updateInteractionMode() {
        switch interactionMode {
        case .native:
            view.isUserInteractionEnabled = true
            setHeaderHitTestingEnabled(true)
        case .forwarded:
            view.isUserInteractionEnabled = false
            setHeaderHitTestingEnabled(false)
        }
    }

    private func configurePageControl() {
        guard case let .display(currentPageColor, pageIndicatorColor) = pageControlConfig else {
            return
        }
        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [Self.self])
        if let currentPageColor {
            appearance.currentPageIndicatorTintColor = currentPageColor
        }
        if let pageIndicatorColor {
            appearance.pageIndicatorTintColor = pageIndicatorColor
        }
    }

    // MARK: - Gesture Forwarding

    private(set) var galleryPanGesture: GalleryPanGestureRecognizer?
    private var panStartOffset: CGPoint = .zero

    private var internalScrollView: UIScrollView? {
        view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
    }

    /// Installs a ``GalleryPanGestureRecognizer`` on the parent scroll view that
    /// classifies direction and drives the UIPageViewController's internal scroll view
    /// for horizontal paging.
    func installGestureForwarding(on parentScrollView: UIScrollView, galleryArea: UIView) {
        let pan = GalleryPanGestureRecognizer(target: self, action: #selector(handleGalleryPan(_:)))
        pan.galleryAreaView = galleryArea
        parentScrollView.addGestureRecognizer(pan)
        galleryPanGesture = pan

        parentScrollView.panGestureRecognizer.require(toFail: pan)
    }

    @objc private func handleGalleryPan(_ pan: GalleryPanGestureRecognizer) {
        guard let scrollView = internalScrollView else { return }

        switch pan.state {
        case .began:
            panStartOffset = scrollView.contentOffset

        case .changed:
            let tx = pan.translation(in: pan.view).x
            let maxX = scrollView.contentSize.width - scrollView.bounds.width
            let newX = min(max(panStartOffset.x - tx, 0), maxX)
            scrollView.contentOffset = CGPoint(x: newX, y: 0)

        case .ended, .cancelled:
            let pageWidth = scrollView.bounds.width
            guard pageWidth > 0 else { return }

            let velocity = pan.velocity(in: pan.view).x
            let currentX = scrollView.contentOffset.x
            let currentPage = currentX / pageWidth

            let targetPage: Int = if abs(velocity) > 500 {
                velocity < 0
                    ? Int(ceil(currentPage))
                    : Int(floor(currentPage))
            } else {
                Int(round(currentPage))
            }

            let maxPage = Int(scrollView.contentSize.width / pageWidth) - 1
            let clampedPage = max(0, min(targetPage, maxPage))
            let targetX = CGFloat(clampedPage) * pageWidth

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                scrollView.contentOffset = CGPoint(x: targetX, y: 0)
            }

        default:
            break
        }
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(
        _: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewController.view.tag > 0 ? viewController.view.tag - 1 : nil else {
            return nil
        }
        return makeImageController(at: index)
    }

    func pageViewController(
        _: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        let index = viewController.view.tag + 1
        guard index < urls.count else { return nil }
        return makeImageController(at: index)
    }

    func presentationCount(for _: UIPageViewController) -> Int {
        if case .display = pageControlConfig {
            return urls.count
        }
        return 0
    }

    func presentationIndex(for _: UIPageViewController) -> Int {
        viewControllers?.first?.view.tag ?? 0
    }

    private func makeImageController(at index: Int) -> UIViewController? {
        guard index >= 0, index < urls.count else { return nil }
        let vc = PageImageController(
            url: urls[index],
            contentMode: imageContentMode,
            backgroundColor: imageBackgroundColor,
            loadingType: loadingType
        )
        if let pageView = vc.view as? PageImageView {
            pageView.hitTestingEnabled = interactionMode == .native
        }
        vc.view.tag = index
        return vc
    }

    private func setHeaderHitTestingEnabled(_ enabled: Bool) {
        for controller in viewControllers ?? [] {
            (controller.view as? PageImageView)?.hitTestingEnabled = enabled
        }
    }
}
