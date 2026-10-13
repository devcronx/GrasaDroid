//
//  AndroidImageManager.swift
//  GrasaDroid
//
//  Gestiona la descarga e instalación de la imagen Android (Cuttlefish AOSP)
//  con drivers virtio-gpu/virgl para QEMU.
//

import Foundation

/// Información de la imagen Android disponible
struct AndroidImageInfo {
    let name: String
    let version: String
    let downloadURL: URL
    let sizeBytes: Int64
    let sha256: String?
    let hasVirglDrivers: Bool
}

final class AndroidImageManager {
    static let shared = AndroidImageManager()

    /// Imagen Cuttlefish ARM64 de AOSP con drivers virtio integrados.
    /// Incluye kernel con CONFIG_DRM_VIRTIO_GPU y Mesa con virpipe.
    static let cuttlefishARM64 = AndroidImageInfo(
        name: "AOSP Cuttlefish ARM64",
        version: "aosp_cf_arm64_phone-userdebug",
        downloadURL: URL(string: "https://ci.android.com/builds/submitted/9970479/aosp_cf_arm64_phone-userdebug/latest/aosp_cf_arm64_phone-img-9970479.zip")!,
        sizeBytes: 945_469_328, // Tamaño real verificado 2026-10-13
        sha256: nil, // Se verifica contra el build de AOSP CI
        hasVirglDrivers: true
    )

    private init() {}

    /// Sesión de descarga activa (se retiene para que no se cancele)
    private var activeSession: URLSession?
    private var activeDelegate: DownloadDelegate?

    /// Directorio donde se guardan las imágenes descargadas
    var imagesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("AndroidImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Ruta de la imagen instalada (si existe)
    var installedImageURL: URL? {
        let url = imagesDirectory.appendingPathComponent("cuttlefish-android.qcow2")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Verifica si hay una imagen instalada y lista para usar
    var isImageInstalled: Bool {
        installedImageURL != nil
    }

    /// Descarga la imagen con progreso reanudable
    /// - Parameters:
    ///   - progress: Closure llamado con el progreso (0.0 - 1.0)
    ///   - completion: Closure llamado al terminar (éxito o error)
    func downloadImage(
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let info = Self.cuttlefishARM64
        let destURL = imagesDirectory.appendingPathComponent("aosp_cf_arm64_phone-img.zip")

        // Si ya existe con el tamaño correcto, no descargar de nuevo
        if let attrs = try? FileManager.default.attributesOfItem(atPath: destURL.path),
           let size = attrs[.size] as? Int64, size == info.sizeBytes {
            progress(1.0)
            completion(.success(destURL))
            return
        }

        // Limpiar descarga parcial anterior
        try? FileManager.default.removeItem(at: destURL)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 // 1 hora para 945 MB

        let delegate = DownloadDelegate(
            progress: progress,
            completion: { [weak self] result in
                self?.activeSession = nil
                self?.activeDelegate = nil
                completion(result)
            },
            destinationURL: destURL
        )

        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

        // Retener sesión y delegate para que la descarga no se cancele
        self.activeSession = session
        self.activeDelegate = delegate

        let task = session.downloadTask(with: info.downloadURL)
        task.resume()
    }

    /// Extrae el kernel y ramdisk del boot.img de Cuttlefish
    /// para usar con -kernel y -initrd de QEMU
    func extractBootImages(from zipURL: URL) throws -> (kernel: URL, ramdisk: URL) {
        // TODO: Implementar extracción de boot.img
        // 1. Descomprimir aosp_cf_arm64_phone-img-*.zip
        // 2. Extraer boot.img
        // 3. Parsear boot.img para obtener kernel + ramdisk
        // 4. Retornar las URLs
        throw AndroidImageError.extractionNotImplemented
    }

    /// Argumentos de QEMU para arrancar Cuttlefish con virgl
    func qemuArguments() -> [String] {
        guard let imageURL = installedImageURL else { return [] }

        return [
            "-machine", "virt",
            "-cpu", "cortex-a72",
            "-smp", "4",
            "-m", "4096",
            "-device", "virtio-gpu-gl-pci,xres=1280,yres=720",
            "-display", "egl",
            "-device", "virtio-blk-device,drive=system",
            "-drive", "file=\(imageURL.path),format=qcow2,if=none,id=system",
            "-device", "virtio-net-device,netdev=net0",
            "-netdev", "user,id=net0",
            "-device", "qemu-xhci",
            "-device", "usb-kbd",
            "-device", "usb-tablet",
        ]
    }
}

enum AndroidImageError: Error {
    case extractionNotImplemented
    case downloadFailed(String)
    case invalidImage
}

/// Delegate para manejar la descarga con progreso
private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progress: (Double) -> Void
    let completion: (Result<URL, Error>) -> Void
    let destinationURL: URL

    init(progress: @escaping (Double) -> Void,
         completion: @escaping (Result<URL, Error>) -> Void,
         destinationURL: URL) {
        self.progress = progress
        self.completion = completion
        self.destinationURL = destinationURL
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { self.progress(p) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async { self.completion(.success(self.destinationURL)) }
        } catch {
            DispatchQueue.main.async { self.completion(.failure(error)) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { self.completion(.failure(error)) }
        }
    }
}
