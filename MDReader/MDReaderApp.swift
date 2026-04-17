import AppKit
import Sparkle
import SwiftUI

final class MDReaderAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct MDReaderApp: App {
    @NSApplicationDelegateAdaptor(MDReaderAppDelegate.self) private var appDelegate
    @StateObject private var readerState = ReaderState()
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(readerState)
                .onOpenURL { url in
                    readerState.openMarkdown(at: url)
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
                .disabled(!updaterController.updater.canCheckForUpdates)
            }
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    readerState.presentOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
