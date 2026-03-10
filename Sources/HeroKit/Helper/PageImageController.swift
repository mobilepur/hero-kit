import UIKit

final class PageImageView: UIControl {
    var hitTestingEnabled: Bool = true

    private enum DragDirection {
        case undecided
        case horizontal
        case vertical
    }

    private var dragDirection: DragDirection = .undecided
    private var startPoint: CGPoint = .zero
    private let dragThreshold: CGFloat = 6

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hitTestingEnabled else { return nil }
        return super.point(inside: point, with: event) ? self : nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard hitTestingEnabled else { return false }
        return super.point(inside: point, with: event)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragDirection = .undecided
        if let touch = touches.first {
            startPoint = touch.location(in: self)
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if dragDirection == .undecided, let touch = touches.first {
            let current = touch.location(in: self)
            let dx = current.x - startPoint.x
            let dy = current.y - startPoint.y
            let absDx = abs(dx)
            let absDy = abs(dy)
            if absDx >= dragThreshold || absDy >= dragThreshold {
                if absDx > absDy {
                    dragDirection = .horizontal
                    hitTestingEnabled = true
                } else {
                    dragDirection = .vertical
                    hitTestingEnabled = false
                }
            }
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragDirection = .undecided
        hitTestingEnabled = true
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragDirection = .undecided
        hitTestingEnabled = true
        super.touchesCancelled(touches, with: event)
    }
}

final class PageImageController: UIViewController {
    private let asyncImageView: AsyncHeaderImageView

    init(
        url: URL,
        contentMode: UIView.ContentMode,
        backgroundColor: UIColor?,
        loadingType: HeroHeader.LoadingType
    ) {
        asyncImageView = AsyncHeaderImageView(
            url: url,
            contentMode: contentMode,
            backgroundColor: backgroundColor,
            loadingType: loadingType
        )
        asyncImageView.isUserInteractionEnabled = false
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PageImageView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        asyncImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(asyncImageView)
        asyncImageView.pinToEdges(of: view)
    }
}
