import CoreGraphics
import AppKit

/// Registers global hotkeys using CGEventTap.
/// Requires Accessibility permission — the same permission we already request
/// for mouse simulation, so no extra setup is needed.
///
/// Registered shortcuts:
///   ⌃⌥⌘S  — Start simulation
///   ⌃⌥⌘X  — Stop  simulation
///   ⌃⌥⌘P  — Pause / Resume
///   ⌃⌥⌘R  — Reset statistics
final class HotKeyManager {

    private weak var viewModel: SimulationViewModel?
    private var eventTap:     CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Virtual key codes (US layout, same as kVK_ANSI_* from HIToolbox)
    private enum Key: Int64 {
        case s = 1, x = 7, p = 35, r = 15
    }

    init(viewModel: SimulationViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Public

    func register() {
        guard AXIsProcessTrusted() else {
            print("[HotKeyManager] Accessibility not granted — hotkeys disabled")
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        // Pass self as unretained userInfo — safe because HotKeyManager lives
        // for the entire app lifetime (retained by AppDelegate).
        let ctx = Unmanaged.passUnretained(self).toOpaque()

        // The callback must be a @convention(c) closure with no captures from
        // the enclosing scope; we thread context through the userInfo pointer.
        eventTap = CGEvent.tapCreate(
            tap:              .cgSessionEventTap,
            place:            .headInsertEventTap,
            options:          .listenOnly,           // observe, don't swallow
            eventsOfInterest: mask,
            callback: { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let event,
                      let userInfo,
                      type == .keyDown else {
                    return event.map(Unmanaged.passRetained)
                }

                // Require exactly ⌃⌥⌘ (no Shift)
                let f = event.flags
                guard f.contains(.maskControl),
                      f.contains(.maskAlternate),
                      f.contains(.maskCommand),
                      !f.contains(.maskShift) else {
                    return Unmanaged.passRetained(event)
                }

                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userInfo)
                                                   .takeUnretainedValue()
                DispatchQueue.main.async { mgr.dispatch(keyCode: keyCode) }
                return Unmanaged.passRetained(event)
            },
            userInfo: ctx
        )

        guard let tap = eventTap else {
            print("[HotKeyManager] CGEventTap creation failed")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[HotKeyManager] Registered ⌃⌥⌘ S/X/P/R via CGEventTap")
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        eventTap      = nil
        runLoopSource = nil
    }

    // MARK: - Private

    private func dispatch(keyCode: Int64) {
        switch Key(rawValue: keyCode) {
        case .s: viewModel?.startSimulation()
        case .x: viewModel?.stopSimulation()
        case .p: viewModel?.togglePause()
        case .r: viewModel?.resetStats()
        case nil: break
        }
    }

    deinit { unregister() }
}
