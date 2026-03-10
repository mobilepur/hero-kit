import UIKit

final class GalleryPageViewController: UIPageViewController,
    UIPageViewControllerDataSource
{
    private let images: [UIImage]
    private let imageContentMode: UIView.ContentMode

    init(images: [UIImage], contentMode: UIView.ContentMode = .scaleAspectFill) {
        self.images = images
        imageContentMode = contentMode
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
        guard index < images.count else { return nil }
        return makeImageController(at: index)
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
