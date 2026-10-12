import Foundation
import Darwin

/// Sonda real de JIT: intenta mapear memoria ejecutable y correr código
/// máquina ARM64 generado en el momento. No adivina: lo intenta de verdad.
///
/// - Si el proceso tiene el entitlement `dynamic-codesigning` o un depurador
///   conectado (StikDebug + pairing file), el kernel permite `MAP_JIT` y la
///   prueba pasa.
/// - Si no, `mmap` falla y la sonda reporta que el JIT no está disponible,
///   sin crashear la app.
enum JITProbe {
    struct Result {
        let available: Bool
        let detail: String
    }

    static func run() -> Result {
        let pageSize = Int(getpagesize())
        let failed = UnsafeMutableRawPointer(bitPattern: -1)

        // 1. El hilo opta por la protección de escritura JIT.
        pthread_jit_write_protect_np(1)

        // 2. Mapear una página JIT (el kernel la niega sin entitlement/depurador).
        let prot: Int32 = PROT_READ | PROT_WRITE
        let flags: Int32 = MAP_ANON | MAP_PRIVATE | MAP_JIT
        guard let page = mmap(nil, pageSize, prot, flags, -1, 0), page != failed else {
            let err = errno
            return Result(
                available: false,
                detail: "El sistema negó la memoria JIT (errno \(err)). " +
                    "Para activarla se necesita un depurador conectado " +
                    "(StikDebug + pairing file desde una computadora)."
            )
        }
        defer { munmap(page, pageSize) }

        // 3. Escribir código máquina ARM64 real: mov w0, #42; ret
        let code: [UInt32] = [0x52800540, 0xD65F03C0]
        code.withUnsafeBufferPointer { buf in
            memcpy(page, buf.baseAddress!, buf.count * MemoryLayout<UInt32>.size)
        }

        // 4. Quitar el permiso de escritura: la página queda ejecutable.
        pthread_jit_write_protect_np(0)

        // 5. Ejecutarla de verdad y comprobar el resultado.
        typealias JITFunction = @convention(c) () -> Int32
        let fn = unsafeBitCast(page, to: JITFunction.self)
        let returned = fn()

        if returned == 42 {
            return Result(
                available: true,
                detail: "¡JIT funcional! El teléfono generó y ejecutó código " +
                    "máquina en memoria (la función retornó 42)."
            )
        } else {
            return Result(
                available: false,
                detail: "La memoria JIT se mapeó pero el código no corrió como " +
                    "se esperaba (retornó \(returned))."
            )
        }
    }
}
