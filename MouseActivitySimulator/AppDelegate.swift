import AppKit

/// Application delegate — wires up services and acts as NSWindowDelegate
/// to hide (rather than destroy) the companion window on close.
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    let viewModel = SimulationViewModel()

    private var menuBarManager: MenuBarManager?
    private var hotKeyManager: HotKeyManager?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(viewModel: viewModel)
        hotKeyManager  = HotKeyManager(viewModel: viewModel)
        hotKeyManager?.register()

        viewModel.checkPermission()

        // Attach window delegate after SwiftUI creates the window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            NSApp.windows.first { $0.canBecomeKey }?.delegate = self
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep alive as a menu-bar utility even when the window is closed
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopSimulation()
        hotKeyManager?.unregister()
    }

    // MARK: - NSWindowDelegate

    /// Hide instead of destroy so we can reopen without re-initialising state.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
