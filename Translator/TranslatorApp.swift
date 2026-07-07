import SwiftUI

@main
struct TranslatorApp: App {
    @StateObject private var settings = Settings.shared
    @State private var showingSettings = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(settings)
        } label: {
            Image(systemName: "translate")
                .symbolVariant(.fill)
        }
        .menuBarExtraStyle(.window)

        Window("Translator 设置", id: "settings") {
            SettingsView()
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
