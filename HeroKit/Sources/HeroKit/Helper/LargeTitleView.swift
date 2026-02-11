import UIKit

public class LargeTitleView: UIView {

    private let title: String
    private let subtitle: String?
    private let allowsLineWrap: Bool
    private let foregroundColor: UIColor
    private let fog: Bool
    private let fogColor: UIColor
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
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
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
        fogColor: UIColor = .systemBackground
    ) {
        self.title = title
        self.subtitle = subtitle
        self.allowsLineWrap = allowsLineWrap
        self.foregroundColor = foregroundColor
        self.fog = fog
        self.fogColor = fogColor
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(labelStack)
        if fog { addSubview(fogView) }

        NSLayoutConstraint.activate([
            labelStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            labelStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            labelStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
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
        titleLabel.preferredMaxLayoutWidth = bounds.width - 32

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
}
