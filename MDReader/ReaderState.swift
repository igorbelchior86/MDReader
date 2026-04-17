import AppKit
import Darwin
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ReaderState: ObservableObject {
    @Published private(set) var currentURL: URL?
    @Published private(set) var renderedHTML: String?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?
    private var renderTask: Task<Void, Never>?
    private var watchSource: DispatchSourceFileSystemObject?
    private var watchFileDescriptor: CInt = -1
    private let watchQueue = DispatchQueue(label: "MDReader.FileWatch")
    private var watchDebounceTask: Task<Void, Never>?
    private var watchRestartTask: Task<Void, Never>?

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
        currentURL = url
        startWatchingCurrentFile()
        renderMarkdown(at: url, clearExistingContent: true, showLoadingState: true, surfaceErrors: true)
    }

    private func renderMarkdown(
        at url: URL,
        clearExistingContent: Bool,
        showLoadingState: Bool,
        surfaceErrors: Bool
    ) {
        renderTask?.cancel()
        watchDebounceTask?.cancel()

        if clearExistingContent {
            renderedHTML = nil
            loadError = nil
        }
        if showLoadingState {
            isLoading = true
        }

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
                if showLoadingState {
                    self?.isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                if surfaceErrors {
                    self?.renderedHTML = nil
                    self?.loadError = error.localizedDescription
                }
                if showLoadingState {
                    self?.isLoading = false
                }
            }
        }
    }

    private func refreshCurrentMarkdownIfNeeded() {
        guard let url = currentURL else { return }
        renderMarkdown(at: url, clearExistingContent: false, showLoadingState: false, surfaceErrors: false)
    }

    private func startWatchingCurrentFile() {
        stopWatchingCurrentFile()
        guard let url = currentURL else { return }

        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        watchFileDescriptor = descriptor
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: watchQueue
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let events = source.data
            Task { @MainActor [weak self] in
                self?.handleWatchEvent(events)
            }
        }

        source.setCancelHandler {
            close(descriptor)
        }

        watchSource = source
        source.resume()
    }

    private func stopWatchingCurrentFile() {
        let source = watchSource
        watchSource = nil
        source?.cancel()
        watchFileDescriptor = -1
    }

    private func handleWatchEvent(_ events: DispatchSource.FileSystemEvent) {
        scheduleDebouncedAutoRefresh()

        if events.contains(.rename) || events.contains(.delete) {
            watchRestartTask?.cancel()
            watchRestartTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                self?.startWatchingCurrentFile()
            }
        }
    }

    private func scheduleDebouncedAutoRefresh() {
        watchDebounceTask?.cancel()
        watchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            self?.refreshCurrentMarkdownIfNeeded()
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
