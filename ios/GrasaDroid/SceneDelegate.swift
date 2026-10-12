import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark

        let library = UINavigationController(rootViewController: LibraryViewController())
        library.tabBarItem = UITabBarItem(
            title: "Biblioteca",
            image: UIImage(systemName: "books.vertical"),
            tag: 0
        )

        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(
            title: "Ajustes",
            image: UIImage(systemName: "gear"),
            tag: 1
        )

        let tabs = UITabBarController()
        tabs.viewControllers = [library, settings]

        window.rootViewController = tabs
        window.makeKeyAndVisible()
        self.window = window
    }
}
