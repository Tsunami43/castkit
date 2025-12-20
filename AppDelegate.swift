import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var captureManager: CaptureManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize capture manager
        captureManager = CaptureManager()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.circle.fill", accessibilityDescription: "Capture")
            button.image?.isTemplate = true
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Screenshot section
        let screenshotSubmenu = NSMenu()
        screenshotSubmenu.addItem(NSMenuItem(title: "Full Screen", action: #selector(captureFullScreen), keyEquivalent: "1"))
        screenshotSubmenu.addItem(NSMenuItem(title: "Select Area", action: #selector(captureArea), keyEquivalent: "2"))

        let screenshotItem = NSMenuItem(title: "📸 Screenshot", action: nil, keyEquivalent: "")
        screenshotItem.submenu = screenshotSubmenu
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        // Screen recording section
        let recordingSubmenu = NSMenu()
        recordingSubmenu.addItem(NSMenuItem(title: "Full Screen", action: #selector(recordFullScreen), keyEquivalent: "3"))
        recordingSubmenu.addItem(NSMenuItem(title: "Select Area", action: #selector(recordArea), keyEquivalent: "4"))
        recordingSubmenu.addItem(NSMenuItem.separator())
        recordingSubmenu.addItem(NSMenuItem(title: "⏹ Stop Recording", action: #selector(stopRecording), keyEquivalent: "s"))

        let recordingItem = NSMenuItem(title: "🎥 Screen Recording", action: nil, keyEquivalent: "")
        recordingItem.submenu = recordingSubmenu
        menu.addItem(recordingItem)

        menu.addItem(NSMenuItem.separator())

        // Audio recording section
        menu.addItem(NSMenuItem(title: "🎙 Start Audio Recording", action: #selector(toggleAudioRecording), keyEquivalent: "a"))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        // Set targets for all items
        for item in menu.items {
            item.target = self
            if let submenu = item.submenu {
                for subItem in submenu.items {
                    subItem.target = self
                }
            }
        }

        statusItem.menu = menu
    }

    @objc private func captureFullScreen() {
        captureManager.captureFullScreenshot()
    }

    @objc private func captureArea() {
        captureManager.captureAreaScreenshot()
    }

    @objc private func recordFullScreen() {
        Task {
            await captureManager.startFullScreenRecording()
        }
    }

    @objc private func recordArea() {
        Task {
            await captureManager.startAreaRecording()
        }
    }

    @objc private func stopRecording() {
        Task {
            await captureManager.stopRecording()
        }
    }

    @objc private func toggleAudioRecording() {
        captureManager.toggleAudioRecording()
        updateAudioMenuItem()
    }

    private func updateAudioMenuItem() {
        if let menu = statusItem.menu {
            for item in menu.items {
                if item.title.contains("Audio") {
                    if captureManager.isAudioRecording {
                        item.title = "🎙 Stop Audio Recording"
                    } else {
                        item.title = "🎙 Start Audio Recording"
                    }
                }
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
