import SwiftUI
import UniformTypeIdentifiers
import CryptoHelpers
import CipherLogic

struct ContentView: View {
    @State private var jsonText: String = "Open a data file to see its contents here..."
    @State private var fileURL: URL?
    
    let key = "p7cGBkuU9UbtfK9v".data(using: .utf8)!
    let iv  = "hBL5v8lV1v9LfD9a".data(using: .utf8)!
    
    @StateObject private var backupSettings = BackupSettings()
    
    var body: some View {
        VStack {
            HStack {
                Button("Open File") { openFile() }
                Button("Save Changes") { saveChanges() }
                Button("Generate Test Data") { createTestData() }
            }
            .padding()
            
            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
        .frame(width: 800, height: 600)
    }
    
    // MARK: - File Operations
    
    func openFile() {
        let panel = NSOpenPanel()
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [UTType(filenameExtension: "dat")!]
        } else {
            panel.allowedFileTypes = ["dat"]
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            fileURL = url
            do {
                let raw = try Data(contentsOf: url)
                
                try createBackup(of: url) // backup before decrypting
                
                guard let decrypted = CipherLogic.shared.decrypt(data: raw, key: key, iv: iv, privateKey: nil),
                      let inflated = decrypted.inflate(),
                      let json = String(data: inflated, encoding: .utf8)
                else {
                    jsonText = "Failed to decrypt or parse file"
                    return
                }
                
                jsonText = json
            } catch {
                jsonText = "Failed to read file: \(error.localizedDescription)"
            }
        }
    }
    
    func saveChanges() {
        guard let url = fileURL else { return }
        guard let data = jsonText.data(using: .utf8),
              let deflated = data.deflate(),
              let encrypted = CipherLogic.shared.encrypt(data: deflated, key: key, iv: iv, publicKey: nil)
        else {
            print("Failed to encrypt data")
            return
        }
        
        do {
            try encrypted.write(to: url)
            print("Save successful")
        } catch {
            print("Failed to write file: \(error.localizedDescription)")
        }
    }
    
    func createTestData() {
        let testJSON = """
        {
            "test":"Hello there! If you're reading this then that means that the data editor works!"
        }
        """
        
        guard let jsonData = testJSON.data(using: .utf8),
              let deflated = jsonData.deflate(),
              let encrypted = CipherLogic.shared.encrypt(data: deflated, key: key, iv: iv, publicKey: nil)
        else {
            jsonText = "Failed to create test save"
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.data]
        panel.nameFieldStringValue = "test"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try encrypted.write(to: url)
                print("Data written to: \(url.path)")
            } catch {
                print("Failed to write data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Backup Logic
    func createBackup(of url: URL) throws {
        guard backupSettings.backupsEnabled else { return }
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "DataEditor"
        let backupDir = appSupport.appendingPathComponent(bundleID).appendingPathComponent("Backups")
        
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupURL = backupDir.appendingPathComponent("\(url.lastPathComponent).\(timestamp).bak")
        
        try FileManager.default.copyItem(at: url, to: backupURL)
        
        try cleanupBackups(in: backupDir, for: url.lastPathComponent)
    }
    
    func cleanupBackups(in folder: URL, for filename: String) throws {
        let contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])
        let backups = contents.filter { $0.lastPathComponent.hasPrefix(filename) }
        
        // Max backups
        if backupSettings.maxBackupsPerFile > 0, backups.count > backupSettings.maxBackupsPerFile {
            let sorted = backups.sorted { (lhs, rhs) -> Bool in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return lhsDate < rhsDate
            }
            let toDelete = sorted.prefix(backups.count - backupSettings.maxBackupsPerFile)
            for file in toDelete { try? FileManager.default.removeItem(at: file) }
        }
        
        // Retention
        if backupSettings.backupRetentionDays > 0 {
            let cutoff = Date().addingTimeInterval(TimeInterval(-backupSettings.backupRetentionDays*24*60*60))
            for file in backups {
                let date = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                if date < cutoff { try? FileManager.default.removeItem(at: file) }
            }
        }
    }
}

#Preview {
    ContentView()
}
