import SwiftUI
import CryptoHelpers

@main
struct Live_Data_EditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
    }
}
