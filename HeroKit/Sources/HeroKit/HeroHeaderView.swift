import UIKit

public class HeroHeaderView: UIStackView {

    public let contentView: UIView
    public private(set) var largeTitleView: UIView?

    public var isCollapsed: Bool = false
    public var isFullyExpanded: Bool = true
    public var isStretching: Bool = false

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
