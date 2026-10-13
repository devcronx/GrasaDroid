import UIKit

/// Pestaña Motor: estado real del JIT (probado en el dispositivo) y del emulador.
final class MotorViewController: UIViewController {
    private let statusCard = UIView()
    private let statusTitle = UILabel()
    private let statusPill = UILabel()
    private let statusDetail = UILabel()
    private let testButton = UIButton(configuration: .filled())
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var downloadProgressView: UIProgressView?
    private var downloadButton: UIButton?

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Motor"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        setupLayout()
        updateStatus(available: nil, detail: "Toca «Probar JIT» para medirlo en este teléfono.")
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

        // Tarjeta de estado del JIT
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = UIColor(white: 0.11, alpha: 1)
        statusCard.layer.cornerRadius = 20
        statusCard.layer.masksToBounds = true
        stack.addArrangedSubview(statusCard)

        statusTitle.translatesAutoresizingMaskIntoConstraints = false
        statusTitle.text = "JIT"
        statusTitle.font = .systemFont(ofSize: 22, weight: .bold)
        statusTitle.textColor = .white
        statusCard.addSubview(statusTitle)

        statusPill.translatesAutoresizingMaskIntoConstraints = false
        statusPill.font = .systemFont(ofSize: 13, weight: .semibold)
        statusPill.textColor = .white
        statusPill.textAlignment = .center
        statusPill.layer.cornerRadius = 12
        statusPill.layer.masksToBounds = true
        statusCard.addSubview(statusPill)

        statusDetail.translatesAutoresizingMaskIntoConstraints = false
        statusDetail.font = .systemFont(ofSize: 14, weight: .regular)
        statusDetail.textColor = UIColor(white: 0.75, alpha: 1)
        statusDetail.numberOfLines = 0
        statusCard.addSubview(statusDetail)

        NSLayoutConstraint.activate([
            statusTitle.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 18),
            statusTitle.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 18),

            statusPill.centerYAnchor.constraint(equalTo: statusTitle.centerYAnchor),
            statusPill.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -18),
            statusPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),
            statusPill.heightAnchor.constraint(equalToConstant: 26),

            statusDetail.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 12),
            statusDetail.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 18),
            statusDetail.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -18),
            statusDetail.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -18),
        ])

        // Botón de prueba
        var config = UIButton.Configuration.filled()
        config.title = "Probar JIT"
        config.image = UIImage(systemName: "bolt.fill")
        config.imagePadding = 8
        config.cornerStyle = .large
        testButton.configuration = config
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(didTapTest), for: .touchUpInside)
        NSLayoutConstraint.activate([testButton.heightAnchor.constraint(equalToConstant: 52)])
        stack.addArrangedSubview(testButton)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        stack.addArrangedSubview(spinner)

        // Cómo se activa el JIT (honesto)
        stack.addArrangedSubview(sectionCard(
            title: "Para activar el JIT",
            body: "iOS solo permite JIT con un depurador conectado. " +
                "El camino conocido es StikDebug + tu pairing file desde una computadora. " +
                "Sin computadora, el camino sería un truco dentro del propio teléfono, " +
                "que en iOS 27.2 beta no está verificado. Esta prueba te dice la verdad " +
                "en tu teléfono, sin adornos."
        ))

        // Estado del emulador
        stack.addArrangedSubview(sectionCard(
            title: "Emulador",
            body: "En construcción. El motor (QEMU + Android) se integra por hitos " +
                "después de confirmar el JIT: sin JIT no hay emulación a velocidad usable."
        ))

        // Descarga de Android
        let androidCard = sectionCard(
            title: "Imagen Android",
            body: "Cuttlefish AOSP ARM64 (~1.5 GB) con drivers virtio-gpu/virgl integrados. " +
                "Necesaria para emular Android con aceleración gráfica."
        )
        stack.addArrangedSubview(androidCard)

        let downloadButton = UIButton(configuration: .filled())
        var dlConfig = UIButton.Configuration.filled()
        dlConfig.title = AndroidImageManager.shared.isImageInstalled ? "Android descargado ✓" : "Descargar Android"
        dlConfig.image = UIImage(systemName: "arrow.down.circle.fill")
        dlConfig.imagePadding = 8
        dlConfig.cornerStyle = .large
        downloadButton.configuration = dlConfig
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(didTapDownloadAndroid), for: .touchUpInside)
        NSLayoutConstraint.activate([downloadButton.heightAnchor.constraint(equalToConstant: 52)])
        stack.addArrangedSubview(downloadButton)

        let downloadProgress = UIProgressView(progressViewStyle: .default)
        downloadProgress.translatesAutoresizingMaskIntoConstraints = false
        downloadProgress.isHidden = true
        stack.addArrangedSubview(downloadProgress)
        self.downloadProgressView = downloadProgress
        self.downloadButton = downloadButton
    }

    @objc private func didTapDownloadAndroid() {
        guard !AndroidImageManager.shared.isImageInstalled else { return }

        downloadButton?.isEnabled = false
        downloadProgressView?.isHidden = false
        downloadProgressView?.progress = 0

        AndroidImageManager.shared.downloadImage(
            progress: { [weak self] p in
                self?.downloadProgressView?.progress = Float(p)
            },
            completion: { [weak self] result in
                switch result {
                case .success:
                    var config = UIButton.Configuration.filled()
                    config.title = "Android descargado ✓"
                    config.image = UIImage(systemName: "checkmark.circle.fill")
                    config.imagePadding = 8
                    config.cornerStyle = .large
                    self?.downloadButton?.configuration = config
                    self?.downloadProgressView?.isHidden = true
                case .failure(let error):
                    var config = UIButton.Configuration.filled()
                    config.title = "Reintentar descarga"
                    config.image = UIImage(systemName: "arrow.down.circle.fill")
                    config.imagePadding = 8
                    config.cornerStyle = .large
                    self?.downloadButton?.configuration = config
                    self?.downloadButton?.isEnabled = true
                    print("[GrasaDroid] Error descargando Android: \(error)")
                }
            }
        )
    }

    private func sectionCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.11, alpha: 1)
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        card.addSubview(titleLabel)

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = UIColor(white: 0.75, alpha: 1)
        bodyLabel.numberOfLines = 0
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func updateStatus(available: Bool?, detail: String) {
        statusDetail.text = detail
        switch available {
        case .some(true):
            statusPill.text = "Disponible"
            statusPill.backgroundColor = UIColor(red: 0.15, green: 0.65, blue: 0.35, alpha: 1)
        case .some(false):
            statusPill.text = "No disponible"
            statusPill.backgroundColor = UIColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 1)
        case .none:
            statusPill.text = "Sin probar"
            statusPill.backgroundColor = UIColor(white: 0.35, alpha: 1)
        }
    }

    @objc private func didTapTest() {
        testButton.isEnabled = false
        spinner.startAnimating()
        updateStatus(available: nil, detail: "Probando…")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = JITProbe.run()
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.testButton.isEnabled = true
                self.updateStatus(available: result.available, detail: result.detail)
            }
        }
    }
}
