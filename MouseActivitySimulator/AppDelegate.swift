import AppKit
import SwiftUI

/// Application delegate for macOS 10.15+.
/// Creates the main NSWindow directly using NSHostingView since
/// SwiftUI's App/WindowGroup lifecycle requires macOS 11.
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    let viewModel = SimulationViewModel()

    private(set) var mainWindow: NSWindow?
    private var menuBarManager: MenuBarManager?
    private var hotKeyManager:  HotKeyManager?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainWindow()
        menuBarManager = MenuBarManager(viewModel: viewModel)
        hotKeyManager  = HotKeyManager(viewModel: viewModel)
        hotKeyManager?.register()
        viewModel.checkPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Stay alive as a menu-bar utility even with the window closed
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel.stopSimulation()
        hotKeyManager?.unregister()
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of destroy so state is preserved
        sender.orderOut(nil)
        return false
    }

    // MARK: - Window creation

    private func createMainWindow() {
        let root = ContentView().environmentObject(viewModel)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 540),
            styleMask:   [.titled, .closable, .miniaturizable, .resizable],
            backing:     .buffered,
            defer:       false
        )
        window.title    = "Mouse Activity Simulator"
        window.minSize  = NSSize(width: 460, height: 500)
        window.contentView = NSHostingView(rootView: root)
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        mainWindow = window
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}
