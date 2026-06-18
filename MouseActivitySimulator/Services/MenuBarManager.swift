import AppKit
import Combine

/// Manages the macOS status-bar icon and its dropdown menu.
/// Uses a programmatically drawn icon instead of SF Symbols
/// so the app runs on macOS 10.15 where NSImage(systemSymbolName:) is unavailable.
final class MenuBarManager {

    private var statusItem: NSStatusItem?
    private weak var viewModel: SimulationViewModel?
    private var bag = Set<AnyCancellable>()

    init(viewModel: SimulationViewModel) {
        self.viewModel = viewModel
        createStatusItem()
        buildMenu()
        observeState()
    }

    // MARK: - Setup

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setIcon(running: false)
    }

    private func buildMenu() {
        let menu = NSMenu()

        menu.addItem(makeItem("Start   ⌃⌥⌘S", #selector(onStart)))
        menu.addItem(makeItem("Stop    ⌃⌥⌘X", #selector(onStop)))
        menu.addItem(makeItem("Pause   ⌃⌥⌘P", #selector(onPause)))
        menu.addItem(.separator())
        menu.addItem(makeItem("Show Window",   #selector(onShowWindow)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func makeItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: - State observation

    private func observeState() {
        viewModel?.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in self?.setIcon(running: running) }
            .store(in: &bag)
    }

    // Draw a simple circle: filled = running, outlined = stopped.
    // Compatible with macOS 10.15 (no SF Symbols required).
    private func setIcon(running: Bool) {
        let size  = NSSize(width: 16, height: 16)
        let image = NSImage(size: size, flipped: false) { bounds in
            let r = bounds.insetBy(dx: 2.5, dy: 2.5)
            let path = NSBezierPath(ovalIn: r)
            path.lineWidth = 1.5
            NSColor.labelColor.withAlphaComponent(0.85).setStroke()
            path.stroke()
            if running {
                NSColor.labelColor.withAlphaComponent(0.85).setFill()
                path.fill()
            }
            return true
        }
        image.isTemplate = true
        statusItem?.button?.image = image
    }

    // MARK: - Menu actions

    @objc private func onStart()  { viewModel?.startSimulation() }
    @objc private func onStop()   { viewModel?.stopSimulation() }
    @objc private func onPause()  { viewModel?.togglePause() }

    @objc private func onShowWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first { $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
    }
}
