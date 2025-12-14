import Cocoa

class AreaSelector {
    private var window: NSWindow?
    private var completion: ((CGRect?) -> Void)?

    func show(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion

        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.isOpaque = false
        window.level = .floating
        window.ignoresMouseEvents = false

        let contentView = AreaSelectorView()
        contentView.onComplete = { [weak self] rect in
            window.close()
            self?.window = nil
            completion(rect)
        }

        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)

        self.window = window
    }
}

class AreaSelectorView: NSView {
    var onComplete: ((CGRect?) -> Void)?
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        if let start = startPoint, let current = currentPoint {
            let rect = rectFromPoints(start, current)

            // Clear the selection area
            NSColor.clear.setFill()
            rect.fill(using: .copy)

            // Draw border
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: rect)
            border.lineWidth = 2
            border.stroke()

            // Draw dimensions
            let size = "\(Int(rect.width)) × \(Int(rect.height))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.white
            ]
            let textSize = size.size(withAttributes: attributes)
            let textRect = NSRect(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            size.draw(in: textRect, withAttributes: attributes)
        }

        // Draw instructions
        let instructions = "Select screen area to record. ESC - cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        let textSize = instructions.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: bounds.height - textSize.height - 20,
            width: textSize.width,
            height: textSize.height
        )

        instructions.draw(in: textRect, withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let end = currentPoint else {
            onComplete?(nil)
            return
        }

        let rect = rectFromPoints(start, end)

        // Convert to screen coordinates
        if let window = window, let screen = window.screen {
            let screenRect = CGRect(
                x: rect.origin.x,
                y: screen.frame.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
            onComplete?(screenRect)
        } else {
            onComplete?(rect)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            onComplete?(nil)
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    private func rectFromPoints(_ p1: NSPoint, _ p2: NSPoint) -> NSRect {
        let x = min(p1.x, p2.x)
        let y = min(p1.y, p2.y)
        let width = abs(p2.x - p1.x)
        let height = abs(p2.y - p1.y)
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
