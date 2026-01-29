For iOS 26 we realised large titles no longer fully work with colored backgrounds.

Apple suggests no longer use colored backgrounds as it interferres with liquid glass layers, but for some of us this is not an option.

https://stackoverflow.com/questions/79795513/navigation-header-disappears-with-custom-background-color-in-form-view-on-ios-26

https://dev.classmethod.jp/en/articles/ios26-navigationstack-large-title-hidden-bug/

import UIKit

protocol HeaderContentController: UIViewController {
    var minHeight: CGFloat? { get }
    var maxHeight: CGFloat { get }
}

protocol CollapsableHeaderViewControllerDelegate: AnyObject {
    func header(_ header: HeaderContentController, didChangeHeight height: CGFloat)
    func header(_ header: HeaderContentController, edgeVisible visible: Bool)
    func headerDidExpand(_ header: HeaderContentController)
}

extension CollapsableHeaderViewControllerDelegate {
    func header(_: HeaderContentController, didChangeHeight _: CGFloat) { }
    func header(_: HeaderContentController, edgeVisible _: Bool) { }
    func headerDidExpand(_: HeaderContentController) { }
}

class CollapsableHeaderViewController: UIViewController {
    weak var headerDelegate: CollapsableHeaderViewControllerDelegate?

    let header: HeaderContentController

    private var headerView: UIView { header.view }

    let scrollView: UIScrollView
    private var observer: NSKeyValueObservation?

    var collectionView: UICollectionView? { return scrollView as? UICollectionView }

    var tableView: UITableView? { return scrollView as? UITableView }

    private lazy var headerTopAnchor: NSLayoutConstraint = headerView.topAnchor
        .constraint(equalTo: view.topAnchor)

    init(header: HeaderContentController, scrollView: UIScrollView) {
        self.header = header
        self.scrollView = scrollView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        prepareScrollView()
        observeScrollView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupSubviews() {
        addChild(header)
        header.didMove(toParent: self)

        [scrollView, headerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: header.maxHeight), headerTopAnchor,
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func prepareScrollView() {
        scrollView.contentInset = UIEdgeInsets(
            top: header.maxHeight - 88,
            left: 0,
            bottom: 0,
            right: 0
        )
        scrollView.contentOffset.y = -header.maxHeight
    }

    private func observeScrollView() {
        observer = scrollView.observe(\UIScrollView.contentOffset, options: .new) {
            [weak self] _, change in guard let newY = change.newValue?.y else { return }
            self?.handleScroll(newY)
        }
    }

    var headerVisible: Bool = true {
        didSet {
            if oldValue != headerVisible {
                headerDelegate?.header(header, edgeVisible: headerVisible)
            }
        }
    }

    private func handleScroll(_ offsetY: CGFloat) {
        let offsetY = -offsetY

        // calculate navbar alpha
        let threshold: CGFloat = navigationController?.navigationBar.frame.maxY ?? 88

        let headerVisible = offsetY > threshold
        self.headerVisible = headerVisible

        let minOffset = max(header.minHeight ?? 0, offsetY)
        if minOffset < header.maxHeight {
            // header collapsed
            let newConstant = minOffset - header.maxHeight
            headerTopAnchor.constant = newConstant
        } else {
            // header fully expanded
            headerDelegate?.headerDidExpand(header)
            headerTopAnchor.constant = 0
        }

        let headerHeight = header.maxHeight + headerTopAnchor.constant
        headerDelegate?.header(header, didChangeHeight: headerHeight)
    }
}

import UIKit

protocol HeaderView: UIView {
    var minHeight: CGFloat? { get }
    var maxHeight: CGFloat { get }
}

protocol CollapsableHeaderControllerDelegate: AnyObject {
    func header(_ header: HeaderView, didChangeHeight height: CGFloat)
    func header(_ header: HeaderView, edgeVisible visible: Bool)
    func headerDidExpand(_ header: HeaderView)
}

extension CollapsableHeaderControllerDelegate {
    func header(_: HeaderView, didChangeHeight _: CGFloat) { }
    func header(_: HeaderView, edgeVisible _: Bool) { }
    func headerDidExpand(_: HeaderView) { }
}

class CollapsableHeaderController: UIViewController {
    weak var headerDelegate: CollapsableHeaderControllerDelegate?

    let header: HeaderView
    let scrollView: UIScrollView
    private var observer: NSKeyValueObservation?

    var collectionView: UICollectionView? { return scrollView as? UICollectionView }

    var tableView: UITableView? { return scrollView as? UITableView }

    private lazy var headerTopAnchor: NSLayoutConstraint = header.topAnchor
        .constraint(equalTo: view.topAnchor)

    init(header: HeaderView, scrollView: UIScrollView) {
        self.header = header
        self.scrollView = scrollView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        prepareScrollView()
        observeScrollView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupSubviews() {
        let collapsableHeader = header
        [scrollView, collapsableHeader].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            collapsableHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collapsableHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collapsableHeader.heightAnchor.constraint(equalToConstant: header.maxHeight),
            headerTopAnchor, scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func prepareScrollView() {
        scrollView.contentInset = UIEdgeInsets(
            top: header.maxHeight - 88,
            left: 0,
            bottom: 0,
            right: 0
        )
        scrollView.contentOffset.y = -header.maxHeight
    }

    private func observeScrollView() {
        observer = scrollView.observe(\UIScrollView.contentOffset, options: .new) {
            [weak self] _, change in guard let newY = change.newValue?.y else { return }
            self?.handleScroll(newY)
        }
    }

    var headerVisible: Bool = true {
        didSet {
            if oldValue != headerVisible {
                headerDelegate?.header(header, edgeVisible: headerVisible)
            }
        }
    }

    private func handleScroll(_ offsetY: CGFloat) {
        let offsetY = -offsetY

        // calculate navbar alpha
        let threshold: CGFloat = navigationController?.navigationBar.frame.maxY ?? 88

        let headerVisible = offsetY > threshold
        self.headerVisible = headerVisible

        let minOffset = max(header.minHeight ?? 0, offsetY)
        if minOffset < header.maxHeight {
            // header collapsed
            let newConstant = minOffset - header.maxHeight
            headerTopAnchor.constant = newConstant
        } else {
            // header fully expanded
            headerDelegate?.headerDidExpand(header)
            headerTopAnchor.constant = 0
        }

        let headerHeight = header.maxHeight + headerTopAnchor.constant
        headerDelegate?.header(header, didChangeHeight: headerHeight)
    }
}
