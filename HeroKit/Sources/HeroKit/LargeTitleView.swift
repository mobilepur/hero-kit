import UIKit

public class LargeTitleView: UIView {

    private let title: String
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

    public init(title: String, allowsLineWrap: Bool = false,
                foregroundColor: UIColor = .label,
                fog: Bool = true,
                fogColor: UIColor = .systemBackground)
    {
        self.title = title
        self.allowsLineWrap = allowsLineWrap
        self.foregroundColor = foregroundColor
        self.fog = fog
        self.fogColor = fogColor
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(titleLabel)
        if fog { addSubview(fogView) }

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
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
}
