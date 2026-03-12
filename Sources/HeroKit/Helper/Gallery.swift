import UIKit

@MainActor
public protocol GalleryDelegate: AnyObject {
    func gallery(_ gallery: Gallery, swipeBeganTo direction: Gallery.SwipeDirection)
    func gallery(_ gallery: Gallery, swipeOffset offset: CGFloat)
    func gallery(_ gallery: Gallery, swipeEndedTo direction: Gallery.SwipeDirection)
    func gallery(_ gallery: Gallery, didChangeImageTo url: URL)
}

public extension GalleryDelegate {
    func gallery(_: Gallery, swipeBeganTo _: Gallery.SwipeDirection) { }
    func gallery(_: Gallery, swipeOffset _: CGFloat) { }
    func gallery(_: Gallery, swipeEndedTo _: Gallery.SwipeDirection) { }
    func gallery(_: Gallery, didChangeImageTo _: URL) { }
}

public final class Gallery: UIViewController, UIScrollViewDelegate {

    public enum SwipeDirection {
        case forward
        case backward
    }

    public weak var delegate: GalleryDelegate?

    private let urls: [URL]
    private let imageContentMode: UIView.ContentMode
    private let imageBackgroundColor: UIColor?
    private let loadingType: HeroHeader.LoadingType
    private let pageControlConfig: HeroHeader.PageControlConfiguration
    private let interactionMode: HeroHeader.GalleryInteractionMode

    private let scrollView = UIScrollView()
    private var pageControl: UIPageControl?
    private var currentPage: Int = 0

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
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupPages()
        setupPageControl()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.isScrollEnabled = interactionMode == .native
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.pinToEdges(of: view)
    }

    private func setupPages() {
        var previousView: UIView?

        for url in urls {
            let pageView = PageImageView()
            pageView.hitTestingEnabled = interactionMode == .native

            let imageView = AsyncHeaderImageView(
                url: url,
                contentMode: imageContentMode,
                backgroundColor: imageBackgroundColor,
                loadingType: loadingType
            )
            imageView.isUserInteractionEnabled = false
            imageView.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(imageView)
            imageView.pinToEdges(of: pageView)

            pageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(pageView)

            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            ])

            if let previous = previousView {
                pageView.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            }

            previousView = pageView
        }

        previousView?.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
    }

    private func setupPageControl() {
        guard case let .display(currentPageColor, pageIndicatorColor) = pageControlConfig else {
            return
        }
        let pc = UIPageControl()
        pc.numberOfPages = urls.count
        pc.currentPage = 0
        if let currentPageColor {
            pc.currentPageIndicatorTintColor = currentPageColor
        }
        if let pageIndicatorColor {
            pc.pageIndicatorTintColor = pageIndicatorColor
        }
        pc.isUserInteractionEnabled = false
        pc.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pc)
        NSLayoutConstraint.activate([
            pc.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pc.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])
        pageControl = pc
    }

    // MARK: - Gesture Forwarding

    private(set) var galleryPanGesture: GalleryPanGestureRecognizer?
    private var panStartOffset: CGPoint = .zero
    private var panStartPage: Int = 0

    func installGestureForwarding(on parentScrollView: UIScrollView, galleryArea: UIView) {
        let pan = GalleryPanGestureRecognizer(target: self, action: #selector(handleGalleryPan(_:)))
        pan.galleryAreaView = galleryArea
        parentScrollView.addGestureRecognizer(pan)
        galleryPanGesture = pan

        parentScrollView.panGestureRecognizer.require(toFail: pan)
    }

    @objc private func handleGalleryPan(_ pan: GalleryPanGestureRecognizer) {
        switch pan.state {
        case .began:
            panStartOffset = scrollView.contentOffset
            panStartPage = currentPage
            delegate?.gallery(self, swipeBeganTo: swipeDirection(for: pan))

        case .changed:
            let tx = pan.translation(in: pan.view).x
            let maxX = scrollView.contentSize.width - scrollView.bounds.width
            let newX = min(max(panStartOffset.x - tx, 0), maxX)
            scrollView.contentOffset = CGPoint(x: newX, y: 0)
            delegate?.gallery(self, swipeOffset: tx)

        case .ended, .cancelled:
            let pageWidth = scrollView.bounds.width
            guard pageWidth > 0 else { return }

            let velocity = pan.velocity(in: pan.view).x
            let currentX = scrollView.contentOffset.x
            let fractionalPage = currentX / pageWidth

            let targetPage: Int = if abs(velocity) > 500 {
                velocity < 0
                    ? Int(ceil(fractionalPage))
                    : Int(floor(fractionalPage))
            } else {
                Int(round(fractionalPage))
            }

            let maxPage = urls.count - 1
            let clampedPage = max(0, min(targetPage, maxPage))
            let targetX = CGFloat(clampedPage) * pageWidth

            delegate?.gallery(self, swipeEndedTo: swipeDirection(for: pan))

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    self.scrollView.contentOffset = CGPoint(x: targetX, y: 0)
                },
                completion: { _ in
                    self.didMoveTo(page: clampedPage)
                }
            )

        default:
            break
        }
    }

    // MARK: - UIScrollViewDelegate

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        panStartPage = currentPage
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
        let direction: SwipeDirection = velocity.x < 0 ? .forward : .backward
        delegate?.gallery(self, swipeBeganTo: direction)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }
        let tx = scrollView.contentOffset.x - CGFloat(panStartPage) * scrollView.bounds.width
        delegate?.gallery(self, swipeOffset: tx)
    }

    public func scrollViewDidEndDecelerating(_: UIScrollView) {
        let page = resolvedPage()
        let direction: SwipeDirection = page >= panStartPage ? .forward : .backward
        delegate?.gallery(self, swipeEndedTo: direction)
        didMoveTo(page: page)
    }

    public func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        didMoveTo(page: resolvedPage())
    }

    // MARK: - Page Tracking

    private func resolvedPage() -> Int {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return 0 }
        return Int(round(scrollView.contentOffset.x / pageWidth))
    }

    private func didMoveTo(page: Int) {
        pageControl?.currentPage = page
        guard page != currentPage, page >= 0, page < urls.count else { return }
        currentPage = page
        delegate?.gallery(self, didChangeImageTo: urls[page])
    }

    private func swipeDirection(for pan: UIPanGestureRecognizer) -> SwipeDirection {
        let tx = pan.translation(in: pan.view).x
        return tx < 0 ? .forward : .backward
    }
}
