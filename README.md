# LogDeck

A macOS log viewer for Mac management tools. One window shows the local logs of every tool on the Mac, each listed newest first the way the tool's own Logs tab lists them.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What it does

- Lists every management tool in one sidebar, with how many logs each has.
- Reads each tool's `/Library/Managed <Bucket>/logs` folder: run sessions (`YYYY-MM-DD/HHMMSS/`), daily folders (`YYYY-MM-DD/`) and flat logs with their rolls, newest first.
- Colours lines by level (error, warning, success, debug, section headers) as the tools' own Logs tabs do.
- Follows a log as it grows, filters lines, and opens the log folder, Console or a `tail -f` in Terminal.
- Says plainly when a tool has no logs yet, is not installed, or needs root to read.

## Tools

| Tool | Role | Logs |
|------|------|------|
| BootstrapMate | Bootstrap | `/Library/Managed Bootstrap/logs/YYYY-MM-DD/HHMMSS/bootstrap.log` |
| ReportMate | Reports | `/Library/Managed Reports/logs/reportmate.log`, daily rolls, launchd output |
| Munki | Installs | `/Library/Managed Installs/logs/` flat logs and `YYYY-MM-DD/HHMM/run.log` |
| Outset | State | `/Library/Managed State/logs/YYYY-MM-DD/HHMMSS/outset.log` |
| Crypt | Encryption | `/Library/Managed Encryption/logs/crypt.log` and daily rolls |
| swiftDialog | Notifications | `/Library/Managed Notifications/logs/YYYY-MM-DD/dialog.log` |
| ManageUsers | Users | `/Library/Managed Users/logs/YYYY-MM-DD/manageusers.log` |
| Utilities | dockutil and others | `/Library/Managed Utilities/logs/YYYY-MM-DD/*.log` |
| Intune | MDM agent | `/Library/Logs/Microsoft/Intune`, `~/Library/Logs/Company Portal` |
| Management Scripts | Scripts | `/Library/Management/Logs` |

The command-line tool reads the same places: `logdeck`, `logdeck <tool>`, `logdeck <tool> -l`, `logdeck <tool> -f`.

## Building

Run the tests:

```bash
swift test
```

Build `build/pkg-root/Applications/Utilities/LogDeck.app`. The app icon is the Icon Composer bundle `resources/LogDeck.icon`, compiled by Xcode 27's actool:

```bash
make app
```

Build the installer package, `dist/LogDeck-<version>.pkg`, which installs LogDeck.app into `/Applications/Utilities` and links `/usr/local/bin/logdeck` to the tool inside it:

```bash
make pkg VERSION=2026.10.07.1530
```

Set `SIGNING_IDENTITY_APP` and `SIGNING_IDENTITY_PKG` (see `.env.example`) to sign, and `NOTARIZATION_PROFILE` for `make notarize`. Pushing a `vYYYY.MM.DD.HHMM` tag publishes an unsigned package as a GitHub release.

## License

MIT
