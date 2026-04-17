import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ReaderState: ObservableObject {
    @Published private(set) var currentURL: URL?
    @Published private(set) var renderedHTML: String?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?
    private var renderTask: Task<Void, Never>?

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedContentTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            openMarkdown(at: url)
        }
    }

    func openMarkdown(at url: URL) {
        renderTask?.cancel()
        currentURL = url
        renderedHTML = nil
        loadError = nil
        isLoading = true

        renderTask = Task { [weak self] in
            do {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isReadableKey])
                guard values.isRegularFile == true, values.isReadable == true else {
                    throw CocoaError(.fileReadNoPermission)
                }

                let html = try await QLMarkdownRenderer.renderAsync(fileURL: url)

                guard !Task.isCancelled else { return }
                self?.renderedHTML = html
                self?.loadError = nil
                self?.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self?.renderedHTML = nil
                self?.loadError = error.localizedDescription
                self?.isLoading = false
            }
        }
    }

    private var allowedContentTypes: [UTType] {
        let markdownType = UTType(filenameExtension: "md")
        if let markdownType {
            return [markdownType, .plainText]
        }
        return [.plainText]
    }
}
