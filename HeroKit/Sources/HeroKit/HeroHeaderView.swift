import UIKit

public class HeroHeaderView: UIStackView {

    public let contentView: UIView
    public internal(set) var largeTitleView: UIView?

    public internal(set) var isLargeTitleHidden: Bool = false

    convenience init(
        contentView: UIView,
        largeTitle: String,
        allowsLineWrap: Bool = false
    ) {
        self.init(
            contentView: contentView,
            largeTitleView: .largeTitleLabel(largeTitle, allowsLineWrap: allowsLineWrap)
        )
    }

    init(contentView: UIView, largeTitleView: UIView? = nil) {
        self.contentView = contentView
        self.largeTitleView = largeTitleView
        super.init(frame: .zero)
        setupStackView()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStackView() {
        axis = .vertical
        alignment = .fill
        distribution = .fill
        clipsToBounds = true

        addArrangedSubview(contentView)
        if let largeTitleView {
            addArrangedSubview(largeTitleView)
        }
    }
}
