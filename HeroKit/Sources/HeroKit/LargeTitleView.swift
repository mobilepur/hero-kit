import UIKit

public class LargeTitleView: UIView {

    private let titleLabel = UILabel()

    public init(title: String, allowsLineWrap: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = .clear

        titleLabel.text = title
        titleLabel.font = UIView.largeTitleFont
        titleLabel.textColor = .label
        titleLabel.numberOfLines = allowsLineWrap ? 2 : 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
