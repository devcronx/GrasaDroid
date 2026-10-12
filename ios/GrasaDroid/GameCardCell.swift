import UIKit

/// Tarjeta de juego para la cuadrícula de la biblioteca.
final class GameCardCell: UICollectionViewCell {
    static let reuseIdentifier = "GameCardCell"

    private let artView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let systemLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.layer.cornerRadius = 18
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = UIColor(white: 0.11, alpha: 1)

        artView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(artView)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        artView.layer.addSublayer(gradientLayer)

        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = .white
        artView.addSubview(symbolView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        systemLabel.translatesAutoresizingMaskIntoConstraints = false
        systemLabel.font = .systemFont(ofSize: 12, weight: .regular)
        systemLabel.textColor = UIColor(white: 0.65, alpha: 1)
        contentView.addSubview(systemLabel)

        NSLayoutConstraint.activate([
            artView.topAnchor.constraint(equalTo: contentView.topAnchor),
            artView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.68),

            symbolView.centerXAnchor.constraint(equalTo: artView.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: artView.centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 44),
            symbolView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: artView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            systemLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            systemLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            systemLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = artView.bounds
    }

    func configure(with item: GameItem) {
        titleLabel.text = item.title
        systemLabel.text = item.system
        symbolView.image = UIImage(
            systemName: item.symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        )
        let base = item.accentColor
        gradientLayer.colors = [base.cgColor, base.withAlphaComponent(0.55).cgColor]
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.contentView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.96, y: 0.96)
                    : .identity
                self.contentView.alpha = self.isHighlighted ? 0.85 : 1.0
            }
        }
    }
}
