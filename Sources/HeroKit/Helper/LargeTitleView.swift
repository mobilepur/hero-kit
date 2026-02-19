import UIKit

public class LargeTitleView: UIView {

    private let title: String
    private let subtitle: String?
    private let allowsLineWrap: Bool
    private let foregroundColor: UIColor
    private let fog: Bool
    private let fogColor: UIColor
    private let titleInsets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat)
    private let accessories: [HeroHeader.Accessory]
    private var fogHeightConstraint: NSLayoutConstraint?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = title
        label.font = UIView.largeTitleFont
        label.textColor = foregroundColor
        label.numberOfLines = allowsLineWrap ? 2 : 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = subtitle
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = foregroundColor.withAlphaComponent(0.8)
        label.numberOfLines = 1
        return label
    }()

    private lazy var labelStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel])
        if subtitle != nil {
            stack.addArrangedSubview(subtitleLabel)
        }
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let trailingAccessories = accessories
            .filter { $0.position == .trailing }
            .map { createAccessoryView(from: $0) }
        let hasTrailingAccessories = !trailingAccessories.isEmpty

        var views: [UIView] = []
        for accessory in accessories where accessory.position == .leading {
            views.append(createAccessoryView(from: accessory))
        }
        views.append(labelStack)
        if hasTrailingAccessories {
            views.append(UIStackView.spacer())
            views.append(contentsOf: trailingAccessories)
        }

        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        labelStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return stack
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [fogColor.cgColor, fogColor.withAlphaComponent(0).cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private lazy var fogView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.addSublayer(gradientLayer)
        return view
    }()

    public init(
        title: String,
        subtitle: String? = nil,
        allowsLineWrap: Bool = false,
        foregroundColor: UIColor = .label,
        fog: Bool = true,
        fogColor: UIColor = .systemBackground,
        titleInsets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) = (
            6,
            16,
            8,
            16
        ),
        accessories: [HeroHeader.Accessory] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.allowsLineWrap = allowsLineWrap
        self.foregroundColor = foregroundColor
        self.fog = fog
        self.fogColor = fogColor
        self.titleInsets = titleInsets
        self.accessories = accessories
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(contentStack)
        if fog { addSubview(fogView) }

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: titleInsets.leading
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -titleInsets.trailing
            ),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: titleInsets.top),
            contentStack.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -titleInsets.bottom
            ),
        ])

        if fog {
            let fogHeight = fogView.heightAnchor.constraint(equalToConstant: 0)
            fogHeightConstraint = fogHeight
            NSLayoutConstraint.activate([
                fogView.topAnchor.constraint(equalTo: topAnchor),
                fogView.leadingAnchor.constraint(equalTo: leadingAnchor),
                fogView.trailingAnchor.constraint(equalTo: trailingAnchor),
                fogHeight,
            ])
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        // Required for multi-line labels to calculate intrinsic content size correctly
        let accessoryWidth = contentStack.arrangedSubviews
            .filter { $0 !== labelStack }
            .reduce(CGFloat(0)) { $0 + $1.intrinsicContentSize.width }
        let spacingWidth = contentStack.spacing * CGFloat(max(
            0,
            contentStack.arrangedSubviews.count - 1
        ))
        titleLabel.preferredMaxLayoutWidth = bounds.width - titleInsets.leading - titleInsets
            .trailing - accessoryWidth - spacingWidth

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = fogView.bounds
        CATransaction.commit()
    }

    /// Controls how much of the title is covered by the fog layer.
    /// 0.0 = fully visible, 1.0 = fully covered.
    func blurFraction(_ fraction: CGFloat) {
        let clamped = max(0, min(1, fraction))
        fogHeightConstraint?.constant = bounds.height * clamped
    }

    /// Updates the displayed title text.
    func updateTitle(_ newTitle: String) {
        titleLabel.text = newTitle
    }

    private func createAccessoryView(from accessory: HeroHeader.Accessory) -> UIView {
        switch accessory.type {
        case let .view(view):
            return view
        case let .button(configuration, action):
            return UIButton(configuration: configuration, primaryAction: action)
        }
    }
}
