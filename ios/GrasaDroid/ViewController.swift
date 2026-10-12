import UIKit

/// GrasaDroid — shell del emulador Android para iOS (M1).
///
/// Plan de hitos:
///   M1 (este shell): la app abre; prueba el pipeline nube -> IPA -> sideload.
///   M2: núcleo QEMU (emulación de sistema ARM64, TCG + JIT) integrado.
///   M3: invitado Android ARM64 arranca hasta shell.
///   M4: pantalla + táctil + instalación de APKs.
///   M5: pulido. Aquí le ganamos a Husk: instalación en un solo IPA,
///       diseño JIT-first y Android afinado para táctil.
///
/// Nota JIT: en iOS stock, una app de sideload solo puede usar JIT cuando un
/// depurador lo habilita (StikDebug + pairing file). El núcleo debe compilarse
/// para usar el motor JIT de TCG; StikDebug lo activa en runtime.
final class ViewController: UIViewController {

    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLabel()
        // TODO(M2): reemplazar este placeholder con la vista del display QEMU.
        // TODO(M4): conectar gestos táctiles -> eventos de input del invitado.
    }

    private func setupLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "GrasaDroid\n\nM1 shell — motor en camino"
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 17, weight: .medium)
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor, constant: -32),
        ])
    }
}
