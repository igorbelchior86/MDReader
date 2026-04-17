# MDReader

I built this because I was fed up with double-clicking `.md` files and having the wrong apps take over: Xcode launching, Antigravity popping open, and still no simple Markdown reader that just opens and renders the file.

`MDReader` is intentionally simple: open a Markdown file and read it with proper rich formatting.

## Why it exists

- Double-click `.md`
- Read immediately
- No editor workflow hijack
- No unnecessary complexity

## Features

- Native macOS app built with SwiftUI
- Rich Markdown rendering powered by bundled QLMarkdown assets
- Works standalone (no separate Quick Look plugin install required)
- Supports opening files from Finder (`Open With` / default app)
- Quits when the last window is closed

## Build

Requirements:

- macOS 14+
- Xcode 15+
- `xcodegen` (optional but recommended when changing `project.yml`)

Build command:

```bash
xcodebuild -project MDReader.xcodeproj -scheme MDReader -configuration Release build
```

## Install

Use the packaged DMG in [`dist/MDReader.dmg`](dist/MDReader.dmg), then drag `MDReader.app` into `/Applications`.

## License

This project is licensed under the GNU General Public License v3.0.

See [`LICENSE`](LICENSE) for details.

This repository also includes QLMarkdown runtime assets. See:

- `MDReader/QLMarkdownSupport/QLMarkdown-LICENSE.txt`
