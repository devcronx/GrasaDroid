import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // M2+: init del motor QEMU (TCG + JIT) aquí.
        // El JIT en iOS stock solo lo habilita un depurador (StikDebug +
        // pairing file); la app debe estar compilada para usar el motor JIT
        // de TCG y StikDebug lo activa en runtime. Sin StikDebug, TCG cae a
        // intérprete (lento pero funcional para pruebas).
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
