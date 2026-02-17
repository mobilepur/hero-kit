import UIKit

final class AsyncHeaderImageView: UIView {

    private let url: URL
    private let loadingType: HeroHeader.LoadingType
    private let imageView = UIImageView()
    private var loadingView: UIView?
    private var loadTask: Task<Void, Never>?

    init(url: URL, loadingType: HeroHeader.LoadingType) {
        self.url = url
        self.loadingType = loadingType
        super.init(frame: .zero)
        setupImageView()
        showLoadingIndicator()
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
        imageView.contentMode = .scaleAspectFill
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
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                guard let image = UIImage(data: data) else { return }
                await MainActor.run {
                    self.imageView.image = image
                    self.hideLoadingIndicator()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.hideLoadingIndicator()
                }
            }
        }
    }
}
