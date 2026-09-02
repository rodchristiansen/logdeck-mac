# LogDeck

A macOS log viewer for Mac admin tooling. One app to find, view, and tail logs from Munki, BootstrapMate, ReportMate, Outset, Intune, and more.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What it does

- **Auto-detects** installed Mac admin tools by scanning known filesystem paths
- **Unified sidebar** showing all detected tools grouped by category
- **Live tail** log files with 1-second polling
- **Search/filter** across log content with severity highlighting (error/warning/debug)
- **Quick actions**: Reveal in Finder, Copy Path, Open in Console.app, Tail in Terminal
- **Per-module toggle** to enable/disable tools you don't use

## Supported Tools

| Tool | Category | Detection |
|------|----------|-----------|
| **Munki** | Package Management | `/usr/local/munki/managedsoftwareupdate` |
| **BootstrapMate** | Bootstrap & Enrollment | `/Applications/Utilities/Managed Bootstrap Install.app` |
| **ReportMate** | Reporting | `/Applications/Utilities/Managed Reports Runner.app` |
| **Outset** | Scripting & Automation | `/usr/local/outset/outset` |
| **Intune** | MDM & Endpoint | `/Library/Logs/Microsoft/Intune` |
| **Management Scripts** | Scripting & Automation | `/Library/Management/Scripts` |
| **Crypt** | Security | `/Library/Crypt` |
| **InstallApplications** | Bootstrap & Enrollment | `/var/log/installapplications` |
| **CommitsListener** | Other | `~/Library/Logs/CommitsListener` |

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16.3+ / Swift 6.2+ for building from source

## Building

```bash
swift build
swift test
```

Or open in Xcode:

```bash
open Package.swift
```

## Architecture

- **Swift 6.2** with strict concurrency checking
- **SwiftUI** with `NavigationSplitView`, `@Observable`, modern APIs
- **`ToolModule` protocol** — each tool implements detection paths, log sources, and support paths
- **`LogTailer`** — `@Observable` service with 1-second file polling
- **`LogReader`** actor — thread-safe file reading with tail support

## Planned

- [ ] Privileged helper (SMAppService) for root-owned log access
- [ ] Unified Log (OSLog) subsystem queries
- [ ] munkipkg wrapper for Munki distribution
- [ ] GitHub Actions CI/CD with signing + notarization
- [ ] DMG packaging for direct download

## License

MIT
