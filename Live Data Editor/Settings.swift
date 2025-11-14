import SwiftUI
import Combine
import AppKit
import CipherLogic

// MARK: - Backup Settings Model
final class BackupSettings: ObservableObject {
    @AppStorage("backupsEnabled") var backupsEnabled: Bool = true
    @AppStorage("maxBackupsPerFile") var maxBackupsPerFile: Int = 5
    @AppStorage("backupRetentionDays") var backupRetentionDays: Int = 30
}

// MARK: - General Settings Model
public final class GeneralSettings: ObservableObject {
    @AppStorage("selectedCipher") var selectedCipher: String = "AES256"
    static let shared = GeneralSettings()
}

// MARK: - Developer Settings Model
final class DeveloperSettings: ObservableObject {
    @AppStorage("showDebugLogs") var showDebugLogs: Bool = false
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var backupSettings = BackupSettings()
    @StateObject private var generalSettings = GeneralSettings()
    @StateObject private var developerSettings = DeveloperSettings()

    // MARK: - Backup State
    @State private var selectedMaxBackups: String = "5"
    @State private var selectedRetention: String = "30"
    @State private var customMaxBackups: String = ""
    @State private var customRetention: String = ""
    @State private var lastValidMaxBackups: Int = 5
    @State private var lastValidRetention: Int = 30

    let presetBackupCounts = ["0", "1", "3", "5", "10", "20", "Custom…"]
    let presetRetentionDays = ["0", "7", "30", "90", "180", "365", "Custom…"]

    // MARK: - General State
    let availableCiphers = ["AES256", "XChaChaPoly", "RSA", "Base64", "Hollow Knight", "None"]

    var body: some View {
        TabView {
            // MARK: - Backups Tab
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Enable Backups", isOn: $backupSettings.backupsEnabled)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Backups Per File:")
                    Picker("", selection: $selectedMaxBackups) {
                        ForEach(presetBackupCounts, id: \.self) { option in
                            Text(option == "0" ? "Unlimited" : option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    if selectedMaxBackups == "Custom…" {
                        TextField("Enter number", text: $customMaxBackups)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit { validateCustomMaxBackups() }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Backup Retention (days):")
                    Picker("", selection: $selectedRetention) {
                        ForEach(presetRetentionDays, id: \.self) { option in
                            Text(option == "0" ? "Unlimited" : option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    if selectedRetention == "Custom…" {
                        TextField("Enter days", text: $customRetention)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit { validateCustomRetention() }
                    }
                }

                Spacer()
            }
            .padding()
            .tabItem { Text("Backups") }

            // MARK: - General Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Cipher:")
                Picker("", selection: $generalSettings.selectedCipher) {
                    ForEach(availableCiphers, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Spacer()
            }
            .padding()
            .tabItem { Text("General") }

            // MARK: - Developer Tab
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Show Debug Logs", isOn: $developerSettings.showDebugLogs)

                Button("Open Application Support Folder") {
                    if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                        let bundleID = Bundle.main.bundleIdentifier ?? "App"
                        let folder = appSupportURL.appendingPathComponent(bundleID)
                        NSWorkspace.shared.activateFileViewerSelecting([folder])
                    }
                }

                Spacer()
            }
            .padding()
            .tabItem { Text("Developer") }
        }
        .frame(width: 400, height: 260)
        .onAppear {
            selectedMaxBackups = "\(backupSettings.maxBackupsPerFile)"
            selectedRetention = "\(backupSettings.backupRetentionDays)"
            lastValidMaxBackups = backupSettings.maxBackupsPerFile
            lastValidRetention = backupSettings.backupRetentionDays
        }
        .onChange(of: selectedMaxBackups) { _, newValue in
            updateMaxBackups(from: newValue)
        }
        .onChange(of: selectedRetention) { _, newValue in
            updateRetention(from: newValue)
        }
        .onChange(of: generalSettings.selectedCipher) { _, newValue in
            updateCipher(from: newValue)
        }
    }

    // MARK: - Validation + Sync
    private func updateMaxBackups(from newValue: String) {
        guard newValue != "Custom…" else { return }
        let parsed = Int(newValue) ?? lastValidMaxBackups
        backupSettings.maxBackupsPerFile = parsed
        lastValidMaxBackups = parsed
    }

    private func updateRetention(from newValue: String) {
        guard newValue != "Custom…" else { return }
        let parsed = Int(newValue) ?? lastValidRetention
        backupSettings.backupRetentionDays = parsed
        lastValidRetention = parsed
    }
  
    public func updateCipher(from newValue: String) {
        CipherLogic.shared.selectedCipher = newValue
    }
    
  

    private func validateCustomMaxBackups() {
        if let customValue = Int(customMaxBackups), customValue >= 0 {
            backupSettings.maxBackupsPerFile = customValue
            lastValidMaxBackups = customValue
        } else {
            customMaxBackups = "\(lastValidMaxBackups)"
        }
    }

    private func validateCustomRetention() {
        if let customValue = Int(customRetention), customValue >= 0 {
            backupSettings.backupRetentionDays = customValue
            lastValidRetention = customValue
        } else {
            customRetention = "\(lastValidRetention)"
        }
    }
}

// MARK: - Settings Window Controller
final class SettingsWindow: NSWindowController, NSWindowDelegate {
    init() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 400, height: 260))
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - App Delegate / Settings Menu Hook
class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu?.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow()
        }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
    }
}
