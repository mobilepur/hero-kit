import UIKit

final class GalleryPageViewController: UIPageViewController,
    UIPageViewControllerDataSource
{
    private let images: [UIImage]
    private let imageContentMode: UIView.ContentMode
    private let pageControlConfig: HeroHeader.PageControlConfiguration

    init(
        images: [UIImage],
        contentMode: UIView.ContentMode = .scaleAspectFill,
        pageControl: HeroHeader.PageControlConfiguration = .display()
    ) {
        self.images = images
        imageContentMode = contentMode
        pageControlConfig = pageControl
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
        if let first = makeImageController(at: 0) {
            setViewControllers([first], direction: .forward, animated: false)
        }
        configurePageControl()
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

    // MARK: - Swipe Forwarding

    /// Installs swipe gesture recognizers on a target view (e.g. the scroll view beneath
    /// the header) so horizontal swipes in the gallery area trigger page transitions.
    func installSwipeGestures(on targetView: UIView, galleryArea: UIView) {
        galleryAreaView = galleryArea

        for direction: UISwipeGestureRecognizer.Direction in [.left, .right] {
            let swipe = UISwipeGestureRecognizer(
                target: self,
                action: #selector(handleSwipe(_:))
            )
            swipe.direction = direction
            targetView.addGestureRecognizer(swipe)
        }
    }

    @objc private func handleSwipe(_ swipe: UISwipeGestureRecognizer) {
        guard let area = galleryAreaView else { return }
        let location = swipe.location(in: area)
        guard area.bounds.contains(location) else { return }

        guard let current = viewControllers?.first else { return }

        switch swipe.direction {
        case .left:
            guard let next = dataSource?.pageViewController(self, viewControllerAfter: current)
            else { return }
            setViewControllers([next], direction: .forward, animated: true)
        case .right:
            guard let prev = dataSource?.pageViewController(self, viewControllerBefore: current)
            else { return }
            setViewControllers([prev], direction: .reverse, animated: true)
        default:
            break
        }
    }

    private weak var galleryAreaView: UIView?

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
        guard index < images.count else { return nil }
        return makeImageController(at: index)
    }

    func presentationCount(for _: UIPageViewController) -> Int {
        if case .display = pageControlConfig {
            return images.count
        }
        return 0
    }

    func presentationIndex(for _: UIPageViewController) -> Int {
        viewControllers?.first?.view.tag ?? 0
    }

    private func makeImageController(at index: Int) -> UIViewController? {
        guard index >= 0, index < images.count else { return nil }
        let vc = UIViewController()
        let imageView = UIImageView(image: images[index])
        imageView.contentMode = imageContentMode
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
        ])
        vc.view.tag = index
        return vc
    }
}
