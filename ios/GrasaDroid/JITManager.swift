//
//  JITManager.swift
//  GrasaDroid
//
//  Gestiona el estado de JIT y el pairing file para StikDebug.
//

import Foundation
import UIKit

final class JITManager {
    static let shared = JITManager()

    private init() {}

    /// Verifica si JIT está disponible en este momento
    /// (requiere un debugger adjunto via StikDebug)
    var isJITAvailable: Bool {
        // Intentar mmap con MAP_JIT
        let pageSize = 16384
        let ptr = mmap(nil, pageSize,
                       PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANON | MAP_JIT,
                       -1, 0)
        if ptr == MAP_FAILED {
            return false
        }
        munmap(ptr, pageSize)
        return true
    }

    /// Directorio para el pairing file
    private var pairingFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("pairing.mobiledevicepairing")
    }

    /// Verifica si hay un pairing file guardado
    var hasPairingFile: Bool {
        FileManager.default.fileExists(atPath: pairingFileURL.path)
    }

    /// Guarda el pairing file importado
    func savePairingFile(from sourceURL: URL) throws {
        if FileManager.default.fileExists(atPath: pairingFileURL.path) {
            try FileManager.default.removeItem(at: pairingFileURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: pairingFileURL)
    }

    /// Instrucciones para activar JIT con StikDebug
    static let stikDebugInstructions = """
    Para activar JIT:

    1. Instala StikDebug en tu iPhone
    2. Abre StikDebug y selecciona GrasaDroid
    3. Toca "Enable JIT"
    4. Vuelve a GrasaDroid - el JIT estará activo

    El pairing file se usa una sola vez para emparejar
    tu iPhone con StikDebug. Después no lo necesitas.
    """
}
