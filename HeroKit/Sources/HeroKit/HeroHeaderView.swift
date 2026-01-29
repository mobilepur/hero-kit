import UIKit

public class HeroHeaderView: UIStackView {

    public let contentView: UIView
    public private(set) var largeTitleView: UIView?

    public internal(set) var isCollapsed: Bool = false
    public internal(set) var isFullyExpanded: Bool = true
    public internal(set) var isStretching: Bool = false
    public internal(set) var isLargeTitleHidden: Bool = false

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
