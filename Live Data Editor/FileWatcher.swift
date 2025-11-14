import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: CInt
    private let queue = DispatchQueue(label: "com.livedataeditor.filewatcher")
    private let callback: () -> Void
    
    init?(path: String, onChange: @escaping () -> Void) {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        
        self.callback = onChange
        self.fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else { return nil }
        
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                            eventMask: [.write, .extend, .rename, .delete],
                                                            queue: queue)
        
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.callback()
            }
        }
        
        src.setCancelHandler { [weak self] in
            guard let fd = self?.fileDescriptor else { return }
            close(fd)
        }
        
        self.source = src
        src.resume()
    }
    
    deinit {
        source?.cancel()
    }
}
