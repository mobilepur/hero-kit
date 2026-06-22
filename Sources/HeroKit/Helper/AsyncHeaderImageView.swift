import UIKit

final class AsyncHeaderImageView: UIView {

    private let url: URL
    private let preloadedImage: UIImage?
    private let placeholderSymbol: String?
    private let imageContentMode: UIView.ContentMode
    private let loadingType: HeroHeader.LoadingType
    private let imageView = UIImageView()
    private var loadingView: UIView?
    private var placeholderView: UIView?
    private var loadTask: Task<Void, Never>?

    var onImageLoaded: ((UIImageView) -> Void)?
    var displayedImageView: UIImageView {
        imageView
    }

    init(
        url: URL,
        contentMode: UIView.ContentMode,
        backgroundColor: UIColor?,
        loadingType: HeroHeader.LoadingType,
        image: UIImage? = nil,
        placeholderSymbol: String? = nil
    ) {
        self.url = url
        preloadedImage = image
        self.placeholderSymbol = placeholderSymbol
        imageContentMode = contentMode
        self.loadingType = loadingType
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor
        setupImageView()
        if preloadedImage == nil { showLoadingIndicator() }
        startLoading()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Setup

    private func setupImageView() {
        imageView.contentMode = imageContentMode
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.pinToEdges(of: self)
        clipsToBounds = true
    }

    private func showLoadingIndicator() {
        switch loadingType {
        case .spinner:
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .secondaryLabel
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            loadingView = spinner
        }
    }

    private func hideLoadingIndicator() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    // MARK: - Loading

    private func startLoading() {
        if let preloadedImage {
            loadTask = Task { [weak self] in
                guard let self, !Task.isCancelled else { return }
                await MainActor.run {
                    self.imageView.image = preloadedImage
                    self.hideLoadingIndicator()
                    self.onImageLoaded?(self.imageView)
                }
            }
            return
        }

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                guard let image = UIImage(data: data) else {
                    await MainActor.run { self.showPlaceholder() }
                    return
                }
                await MainActor.run {
                    self.imageView.image = image
                    self.hideLoadingIndicator()
                    self.onImageLoaded?(self.imageView)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.showPlaceholder() }
            }
        }
    }

    private func showPlaceholder() {
        hideLoadingIndicator()
        guard placeholderView == nil,
              let placeholderSymbol,
              let symbol = UIImage(systemName: placeholderSymbol)
        else { return }

        let symbolView = UIImageView(
            image: symbol.withTintColor(.systemGray5, renderingMode: .alwaysOriginal)
        )
        symbolView.contentMode = .scaleAspectFit
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolView)
        NSLayoutConstraint.activate([
            symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.35),
            symbolView.widthAnchor.constraint(equalTo: symbolView.heightAnchor),
        ])
        placeholderView = symbolView
    }
}
