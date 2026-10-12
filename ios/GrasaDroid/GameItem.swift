import UIKit

/// Un juego/imagen del sistema en la biblioteca de GrasaDroid.
struct GameItem: Hashable {
    let identifier = UUID()
    let title: String
    let system: String
    let detail: String
    let accentColor: UIColor
    let symbolName: String
    let lastPlayedText: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: GameItem, rhs: GameItem) -> Bool {
        lhs.identifier == rhs.identifier
    }

    /// Datos de muestra para que la biblioteca se vea viva sin ROMs importadas.
    static func sampleLibrary() -> [GameItem] {
        [
            GameItem(
                title: "Neon Racer",
                system: "Android",
                detail: "Carreras arcade",
                accentColor: UIColor(red: 0.45, green: 0.25, blue: 0.95, alpha: 1),
                symbolName: "car.fill",
                lastPlayedText: "Ayer"
            ),
            GameItem(
                title: "Pixel Quest",
                system: "Android",
                detail: "Aventura retro",
                accentColor: UIColor(red: 0.10, green: 0.60, blue: 0.45, alpha: 1),
                symbolName: "gamecontroller.fill",
                lastPlayedText: "Hace 3 días"
            ),
            GameItem(
                title: "Orbital",
                system: "Android",
                detail: "Puzle espacial",
                accentColor: UIColor(red: 0.90, green: 0.35, blue: 0.20, alpha: 1),
                symbolName: "globe",
                lastPlayedText: nil
            ),
            GameItem(
                title: "Shadow Blade",
                system: "Android",
                detail: "Acción",
                accentColor: UIColor(red: 0.15, green: 0.25, blue: 0.55, alpha: 1),
                symbolName: "bolt.fill",
                lastPlayedText: "La semana pasada"
            ),
        ]
    }
}
