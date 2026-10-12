import UIKit

/// Ficha del juego: portada, botón Jugar e información.
final class GameDetailViewController: UIViewController {
    private let item: GameItem

    init(item: GameItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        title = item.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    private func setupLayout() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40),
        ])

        // Portada con degradado
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.layer.cornerRadius = 22
        header.layer.masksToBounds = true
        let gradient = CAGradientLayer()
        gradient.colors = [
            item.accentColor.cgColor,
            item.accentColor.withAlphaComponent(0.5).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        header.layer.addSublayer(gradient)
        // El frame se ajusta cuando la vista ya tiene tamaño.
        DispatchQueue.main.async { gradient.frame = header.bounds }

        let symbol = UIImageView(
            image: UIImage(
                systemName: item.symbolName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 64, weight: .medium)
            )
        )
        symbol.translatesAutoresizingMaskIntoConstraints = false
        symbol.tintColor = .white
        symbol.contentMode = .scaleAspectFit
        header.addSubview(symbol)

        NSLayoutConstraint.activate([
            header.heightAnchor.constraint(equalToConstant: 220),
            symbol.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            symbol.widthAnchor.constraint(equalToConstant: 80),
            symbol.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Botón Jugar
        var config = UIButton.Configuration.filled()
        config.title = "Jugar"
        config.image = UIImage(systemName: "play.fill")
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = item.accentColor
        let playButton = UIButton(configuration: config)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        NSLayoutConstraint.activate([
            playButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        // Filas de información
        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 10
        info.addArrangedSubview(infoRow(title: "Sistema", value: item.system))
        info.addArrangedSubview(infoRow(title: "Género", value: item.detail))
        info.addArrangedSubview(
            infoRow(title: "Última vez", value: item.lastPlayedText ?? "Sin jugar")
        )

        stack.addArrangedSubview(header)
        stack.addArrangedSubview(playButton)
        stack.addArrangedSubview(info)
    }

    private func infoRow(title: String, value: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = .label

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)
        return row
    }

    @objc private func didTapPlay() {
        let alert = UIAlertController(
            title: item.title,
            message: "El motor de emulación está en camino. Esta versión solo muestra la interfaz.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alert, animated: true)
    }
}
