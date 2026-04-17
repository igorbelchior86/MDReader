import Foundation

enum QLMarkdownRendererError: LocalizedError {
    case supportAssetsMissing
    case cliMissing
    case cliFailed(code: Int32, message: String)

    var errorDescription: String? {
        switch self {
        case .supportAssetsMissing:
            return "QLMarkdown support assets are missing from the app bundle."
        case .cliMissing:
            return "QLMarkdown renderer executable is missing."
        case .cliFailed(let code, let message):
            if message.isEmpty {
                return "Markdown renderer failed (exit code \(code))."
            }
            return "Markdown renderer failed (exit code \(code)): \(message)"
        }
    }
}

enum QLMarkdownRenderer {
    static func renderAsync(fileURL: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try render(fileURL: fileURL)
        }.value
    }

    static func render(fileURL: URL) throws -> String {
        let supportRoot = try supportRootURL()
        let resourcesURL = supportRoot.appendingPathComponent("Resources", isDirectory: true)
        let cliURL = resourcesURL.appendingPathComponent("qlmarkdown_cli", isDirectory: false)

        guard FileManager.default.fileExists(atPath: cliURL.path) else {
            throw QLMarkdownRendererError.cliMissing
        }

        try ensureExecutable(at: cliURL)

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let process = Process()
        process.executableURL = cliURL
        process.arguments = [
            "--autolink", "on",
            "--table", "on",
            "--tasklist", "on",
            "--strikethrough", "double",
            "--syntax-highlight", "on",
            "--heads-anchor", "on",
            "--about", "off",
            fileURL.path
        ]
        process.currentDirectoryURL = fileURL.deletingLastPathComponent()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let stderr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw QLMarkdownRendererError.cliFailed(code: process.terminationStatus, message: stderr)
        }

        guard let html = String(data: outputData, encoding: .utf8), !html.isEmpty else {
            throw QLMarkdownRendererError.cliFailed(code: process.terminationStatus, message: "Renderer produced empty output.")
        }

        return html
    }

    private static func supportRootURL() throws -> URL {
        guard let resourcesURL = Bundle.main.resourceURL else {
            throw QLMarkdownRendererError.supportAssetsMissing
        }

        let supportRoot = resourcesURL.appendingPathComponent("QLMarkdownSupport", isDirectory: true)
        guard FileManager.default.fileExists(atPath: supportRoot.path) else {
            throw QLMarkdownRendererError.supportAssetsMissing
        }

        return supportRoot
    }

    private static func ensureExecutable(at url: URL) throws {
        if FileManager.default.isExecutableFile(atPath: url.path) {
            return
        }

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
