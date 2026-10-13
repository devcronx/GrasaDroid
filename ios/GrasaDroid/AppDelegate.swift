import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Auto-JIT via self-debugging: la app se adjunta su propio debugger
        // para habilitar MAP_JIT sin necesidad de StikDebug externo.
        // Esto debe correr ANTES de que QEMU intente usar TCG/JIT.
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = JITEnabler.enableJIT()
            print("[GrasaDroid] Auto-JIT: \(ok ? "ACTIVO" : "no disponible")")
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}
