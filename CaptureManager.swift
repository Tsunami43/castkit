import Foundation
import AppKit
import ScreenCaptureKit
import AVFoundation

@MainActor
class CaptureManager: NSObject {
    private var screenRecorder: ScreenRecorder?
    private var audioRecorder: AudioRecorder?

    var isAudioRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    // MARK: - Screenshots

    func captureFullScreenshot() {
        guard let screen = NSScreen.main else {
            showAlert(title: "Error", message: "Failed to access the screen")
            return
        }

        let screenRect = screen.frame
        guard let image = captureScreen(rect: screenRect) else {
            showAlert(title: "Error", message: "Failed to take screenshot")
            return
        }

        saveImage(image, name: "Screenshot")
    }

    func captureAreaScreenshot() {
        // Use system screenshot tool for area selection
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // Interactive mode, copy to clipboard

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                // Also save to file
                saveScreenshotFromClipboard()
            }
        } catch {
            showAlert(title: "Error", message: "Failed to launch screencapture: \(error.localizedDescription)")
        }
    }

    private func captureScreen(rect: CGRect) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))
    }

    private func saveScreenshotFromClipboard() {
        let pasteboard = NSPasteboard.general
        guard let image = NSImage(pasteboard: pasteboard) else {
            return
        }
        saveImage(image, name: "Screenshot")
    }

    private func saveImage(_ image: NSImage, name: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\(name)_\(dateString).png"

        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let fileURL = downloadsURL.appendingPathComponent(fileName)

        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: fileURL)
                showNotification(title: "Screenshot Saved", body: "File: \(fileName)")
            } catch {
                showAlert(title: "Error", message: "Failed to save screenshot: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Screen Recording

    func startFullScreenRecording() async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                showAlert(title: "Error", message: "No displays found")
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            screenRecorder = ScreenRecorder()
            try await screenRecorder?.startRecording(with: filter)
            showNotification(title: "Recording Started", body: "Recording full screen")
        } catch {
            showAlert(title: "Error", message: "Failed to start recording: \(error.localizedDescription)")
        }
    }

    func startAreaRecording() async {
        // For area recording, we'll use a simple window selection approach
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                showAlert(title: "Error", message: "No displays found")
                return
            }

            // Show window to select area
            let areaSelector = AreaSelector()
            areaSelector.show { selectedRect in
                guard let rect = selectedRect else { return }

                Task { @MainActor in
                    let filter = SCContentFilter(display: display, excludingWindows: [])
                    self.screenRecorder = ScreenRecorder()
                    self.screenRecorder?.cropRect = rect
                    try? await self.screenRecorder?.startRecording(with: filter)
                    self.showNotification(title: "Recording Started", body: "Recording selected area")
                }
            }
        } catch {
            showAlert(title: "Error", message: "Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() async {
        guard let recorder = screenRecorder else {
            showAlert(title: "Information", message: "Recording was not started")
            return
        }

        do {
            let fileURL = try await recorder.stopRecording()
            screenRecorder = nil
            showNotification(title: "Recording Saved", body: "File: \(fileURL.lastPathComponent)")
        } catch {
            showAlert(title: "Error", message: "Failed to stop recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio Recording

    func toggleAudioRecording() {
        if let recorder = audioRecorder, recorder.isRecording {
            stopAudioRecording()
        } else {
            startAudioRecording()
        }
    }

    private func startAudioRecording() {
        audioRecorder = AudioRecorder()
        do {
            try audioRecorder?.startRecording()
            showNotification(title: "Audio Recording Started", body: "Recording from microphone")
        } catch {
            showAlert(title: "Error", message: "Failed to start audio recording: \(error.localizedDescription)")
        }
    }

    private func stopAudioRecording() {
        guard let recorder = audioRecorder else { return }

        do {
            let fileURL = try recorder.stopRecording()
            audioRecorder = nil
            showNotification(title: "Audio Recording Saved", body: "File: \(fileURL.lastPathComponent)")
        } catch {
            showAlert(title: "Error", message: "Failed to save recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
