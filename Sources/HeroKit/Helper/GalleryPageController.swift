import UIKit

final class GalleryPageController: UIViewController, UIScrollViewDelegate {

    private let urls: [URL]
    private let imageContentMode: UIView.ContentMode
    private let imageBackgroundColor: UIColor?
    private let loadingType: HeroHeader.LoadingType
    private let pageControlConfig: HeroHeader.PageControlConfiguration
    private let interactionMode: HeroHeader.GalleryInteractionMode

    private let scrollView = UIScrollView()
    private var pageControl: UIPageControl?

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

    override func viewDidLoad() {
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

            let maxPage = urls.count - 1
            let clampedPage = max(0, min(targetPage, maxPage))
            let targetX = CGFloat(clampedPage) * pageWidth

            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction],
                animations: {
                    self.scrollView.contentOffset = CGPoint(x: targetX, y: 0)
                },
                completion: { _ in
                    self.pageControl?.currentPage = clampedPage
                }
            )

        default:
            break
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_: UIScrollView) {
        updatePageControl()
    }

    func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        updatePageControl()
    }

    private func updatePageControl() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        pageControl?.currentPage = Int(round(scrollView.contentOffset.x / pageWidth))
    }
}
