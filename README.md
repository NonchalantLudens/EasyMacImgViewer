# EasyMacImgViewer
> A lightweight macOS image viewer with Live Photo support.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey.svg)
![Language](https://img.shields.io/badge/language-Swift-orange.svg)
![Release](https://img.shields.io/badge/release-v1.0.0-blue.svg)

[English](README.md) | [简体中文](README.zh-CN.md)

A native SwiftUI image viewer with zero third-party dependencies: folder-aware navigation, multi-window, smooth zoom, Live Photo playback, animated GIF/WebP, and wide format support including camera RAW.

## Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Building](#building)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Folder-aware navigation** — auto-scans the folder of the opened file, sorted in Finder natural order; switch via mouse (click left/right edges) or keyboard (←/→/Space)
- **Multi-window** — opening another image always opens a new independent window (Finder double-click, ⌘O multi-select)
- **Zoom** — toolbar buttons with smooth animation, trackpad pinch, ⌘+scroll, double-click toggles 100%/fit, ⌘0/⌘1/⌘+/⌘−
- **Live Photo** — loop playback with sound for paired .mov/.mp4 videos; supports same-name and `_HEVC` naming patterns plus ContentIdentifier metadata fallback; hints when the video part was not transferred
- **Animated images** — GIF / animated WebP frame playback
- **Formats** — JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / common camera RAW (CR2 / NEF / ARW / DNG / RAF / ORF / RW2 etc.), with EXIF orientation correction
- **Drag to pan** — when zoomed in, mouse drag pans the image (grab cursor, clamped edges)
- **Native macOS UI** — unified toolbar, frosted-glass info overlay, dark-mode aware

## System Requirements

| Item | Requirement |
| --- | --- |
| macOS | 15.0 (Sequoia) or later |
| Architecture | Apple Silicon or Intel |

## Installation

Download the latest installer from the [Releases](https://github.com/NonchalantLudens/EasyMacImgViewer/releases) page:

```bash
# Option 1: GUI — open the DMG and drag EasyMacImgViewer into Applications
open EasyMacImgViewer-1.0.0.dmg

# Option 2: CLI — mount, copy, eject
hdiutil attach EasyMacImgViewer-1.0.0.dmg
cp -R "/Volumes/EasyMacImgViewer/EasyMacImgViewer.app" /Applications/
hdiutil detach /Volumes/EasyMacImgViewer
```

First launch on a not-notarized build: right-click the app → Open → confirm.

## Usage

| Operation | How |
| --- | --- |
| Open images | ⌘O, or double-click files in Finder, or drag onto the app |
| Previous / next image | ← / → / Space, or click left/right 12% edge of the window |
| Zoom in / out | Toolbar buttons, trackpad pinch, ⌘+scroll, ⌘+ / ⌘− |
| Fit window / actual size | Double-click, ⌘0 / ⌘1 |
| Pan when zoomed | Drag with mouse (grab cursor) |
| Play Live Photo | Click the "Live" badge or the toolbar button |
| Play / pause animated GIF | Toolbar play button |

## Troubleshooting

1. **A Live Photo shows as a static image**
   - Check that the paired `.mov` file exists in the same folder with the same name (or `_HEVC` suffix). AirDrop and many sharing channels only transfer the still image; use AirDrop to Photos, or download originals via icloudpd.
2. **RAW files fail to open**
   - Confirmed decode requires macOS 15+; very large RAW files take a few seconds — a progress indicator is shown.
3. **Zoom speed feels off**
   - Scroll-wheel zoom now requires ⌘; trackpad pinch is unaffected.
4. **"Video part not transferred" hint appears**
   - The HEIC contains Live Photo metadata but the companion MOV is missing — re-transfer the files keeping the pair intact.

## Building

```sh
xcodebuild -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -configuration Release build
```

Product: `build/Build/Products/Release/EasyMacImgViewer.app`

Run tests:

```sh
xcodebuild test -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -destination 'platform=macOS'
```

## Project Structure

```text
EasyMacImgViewer/
├── App/        App entry, window scenes, file-open handling, menu commands
├── Models/     Viewer state model (navigation / zoom / pan)
├── Services/   Folder scanning, image decoding, Live Photo pairing
├── Views/      Window / canvas / toolbar / overlay views
├── LivePhoto/  Live Photo and animated image players
└── Resources/  Info.plist, app icon
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and commit conventions.

## License

[MIT](LICENSE) © 2026 NonchalantLudens
