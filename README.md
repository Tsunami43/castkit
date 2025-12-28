# CastKit

A **macOS menu bar application** that provides quick access to screen capture, screen recording, and audio recording features.

## Features

### Screenshots
- **Full Screen** — Capture the entire screen with one click
- **Select Area** — Interactive area selection for screenshots with visual overlay

### Screen Recording
- **Full Screen** — Record the entire screen
- **Select Area** — Record a selected portion of the screen
- Output format: **MP4** (H.264)
- Quality: **1920×1080** at **30 FPS**

### Voice Recorder
- Record audio from microphone
- Output format: **M4A** (AAC codec)
- High quality audio: **44.1 kHz, stereo**

## Requirements

- **macOS** 13.0 or newer
- **Swift** 6.0
- **Xcode** 15.0 or newer

## Installation and Running

### Building with Xcode

1. Open the project in Xcode
2. Configure **Bundle Identifier** in project settings
3. Ensure the correct entitlements and `Info.plist` are selected
4. Run the project (**⌘R**)

### Creating Project from Scratch

1. Open Xcode
2. **File → New → Project**
3. Select **macOS → App**
4. Project settings:
   - **Product Name:** `CastKit`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Organization Identifier:** your identifier
5. Replace created files with files from this repository
6. Configure project settings:
   - **General → Deployment Info:** macOS 13.0
   - **Signing & Capabilities:**
     - Disable App Sandbox or use entitlements file
     - Add capabilities for Audio Input, Camera
   - **Build Settings:**
     - Swift Language Version: Swift 6
   - **Info tab:** add `Info.plist`

## Permissions

On first launch, macOS will request the following permissions:

- **Screen Recording** — Required for creating screenshots and recording screen
- **Microphone** — Required for audio recording
- **File Access** — Required for saving recordings to Downloads folder

Grant these permissions in **System Settings → Privacy & Security** for full functionality.

## Usage

1. After launch, the CastKit icon will appear in the **menu bar** (upper right corner)
2. Click on the icon to open the menu
3. Select the desired function:
   - **Screenshot** → Full Screen / Select Area
   - **Screen Recording** → Full Screen / Select Area / Stop Recording
   - **Audio Recording** → Start / Stop

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘1** | Full screen screenshot |
| **⌘2** | Area screenshot |
| **⌘3** | Full screen recording |
| **⌘4** | Area screen recording |
| **⌘S** | Stop screen recording |
| **⌘A** | Start/Stop audio recording |
| **⌘Q** | Quit application |

## File Saving

All files are automatically saved to the **Downloads** folder with timestamp-based naming:

| Type | Format | Example |
|------|--------|---------|
| Screenshots | `Screenshot_YYYY-MM-DD_HH-mm-ss.png` | `Screenshot_2026-01-12_14-30-45.png` |
| Screen Recordings | `ScreenRecording_YYYY-MM-DD_HH-mm-ss.mp4` | `ScreenRecording_2026-01-12_14-30-45.mp4` |
| Audio Recordings | `AudioRecording_YYYY-MM-DD_HH-mm-ss.m4a` | `AudioRecording_2026-01-12_14-30-45.m4a` |

## Project Structure

```
CastKit/
├── MenuBarCaptureApp.swift         # Main application entry point
├── AppDelegate.swift               # Menu bar management and app delegate
├── CaptureManager.swift            # Coordinator for all capture operations
├── ScreenRecorder.swift            # Screen recording (ScreenCaptureKit API)
├── AudioRecorder.swift             # Audio recording (AVFoundation)
├── AreaSelector.swift              # Interactive area selection UI
├── Info.plist                      # App configuration and permissions
└── MenuBarCaptureApp.entitlements  # System capabilities and entitlements
```

## Technologies

- **SwiftUI** — Modern declarative UI framework
- **ScreenCaptureKit** — High-performance screen capture and recording API (macOS 13+)
- **AVFoundation** — Audio/video recording and processing framework
- **AppKit** — macOS menu bar integration and system interaction

## Implementation Details

- Application runs as a **menu bar utility** without Dock icon (`LSUIElement = true`)
- **Area selection** uses custom overlay window with drag-to-select interface
- **Screenshots** utilize system `screencapture` utility for area capture
- **Screen recording** leverages ScreenCaptureKit for efficient, high-quality capture
- All recordings include **automatic timestamping** for organization

## License

MIT
