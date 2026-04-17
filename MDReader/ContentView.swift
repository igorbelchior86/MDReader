import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var readerState: ReaderState

    var body: some View {
        Group {
            if let error = readerState.loadError {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Could not open file")
                        .font(.title3.weight(.semibold))
                    Text(error)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(24)
            } else if readerState.isLoading {
                ProgressView("Rendering Markdown…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let html = readerState.renderedHTML, let currentURL = readerState.currentURL {
                MarkdownWebView(html: html, baseURL: currentURL.deletingLastPathComponent())
            } else {
                VStack(spacing: 10) {
                    Text("Open a Markdown file")
                        .font(.title3.weight(.semibold))
                    Text("Double-click an .md file in Finder or press ⌘O.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(readerState.currentURL?.lastPathComponent ?? "MD Reader")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Open") {
                    readerState.presentOpenPanel()
                }
            }
        }
    }
}
