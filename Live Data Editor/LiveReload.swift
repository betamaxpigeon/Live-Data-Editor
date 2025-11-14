import Foundation
import Combine
import CryptoHelpers
import SwiftUI
import CipherLogic

final class LiveReload: ObservableObject {
    @Published var jsonText: String = ""
    private var fileURL: URL?
    private var fileMonitor: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "LiveReloadQueue")
    
    let key = "p7cGBkuU9UbtfK9v".data(using: .utf8)!
    let iv  = "hBL5v8lV1v9LfD9a".data(using: .utf8)!
    
    func startMonitoring(file url: URL) {
        stopMonitoring()
        fileURL = url
        
        let fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        fileMonitor = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                                eventMask: .write,
                                                                queue: queue)
        fileMonitor?.setEventHandler { [weak self] in
            self?.reloadFile()
        }
        fileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }
        fileMonitor?.resume()
        
        // initial load
        reloadFile()
    }
    
    func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }
    
    private func reloadFile() {
        guard let url = fileURL else { return }
        do {
            let raw = try Data(contentsOf: url)
            if let decrypted = CipherLogic.shared.decrypt(data: raw, key: key, iv: iv, privateKey: nil),
               let inflated = decrypted.inflate(),
               let json = String(data: inflated, encoding: .utf8) {
                DispatchQueue.main.async { [weak self] in
                    self?.jsonText = json
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.jsonText = "Failed to decrypt or parse file"
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.jsonText = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }
}
