import AppKit
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(readerState)
                .onOpenURL { url in
                    readerState.openMarkdown(at: url)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    readerState.presentOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
