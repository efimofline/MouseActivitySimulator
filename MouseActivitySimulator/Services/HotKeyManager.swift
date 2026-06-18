import Carbon.HIToolbox
import AppKit

/// Registers global hotkeys via the Carbon Event Manager.
/// Works system-wide regardless of which app is in front.
///
/// Registered shortcuts:
///   ⌃⌥⌘S  — Start simulation
///   ⌃⌥⌘X  — Stop  simulation
///   ⌃⌥⌘P  — Pause / Resume
///   ⌃⌥⌘R  — Reset statistics
final class HotKeyManager {

    private weak var viewModel: SimulationViewModel?

    private var hotKeyRefs:      [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?

    // Unique 4-char signature for this app's hotkeys ('MASI')
    private let kSig: OSType = 0x4D415349

    private enum Action: UInt32 {
        case start = 1, stop, pause, reset
    }

    init(viewModel: SimulationViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Public

    func register() {
        installCarbonHandler()

        let mods = UInt32(controlKey | optionKey | cmdKey)
        registerKey(vk: UInt32(kVK_ANSI_S), mods: mods, action: .start)
        registerKey(vk: UInt32(kVK_ANSI_X), mods: mods, action: .stop)
        registerKey(vk: UInt32(kVK_ANSI_P), mods: mods, action: .pause)
        registerKey(vk: UInt32(kVK_ANSI_R), mods: mods, action: .reset)
    }

    func unregister() {
        hotKeyRefs.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        if let h = eventHandlerRef { RemoveEventHandler(h); eventHandlerRef = nil }
    }

    // MARK: - Private

    private func registerKey(vk: UInt32, mods: UInt32, action: Action) {
        var hkID = EventHotKeyID(signature: kSig, id: action.rawValue)
        var ref:  EventHotKeyRef?
        if RegisterEventHotKey(vk, mods, hkID, GetApplicationEventTarget(), 0, &ref) == noErr,
           let ref {
            hotKeyRefs.append(ref)
        }
    }

    private func installCarbonHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )

        // Passed as userData — must not form a strong cycle; HotKeyManager
        // is retained by AppDelegate for the app's lifetime, so passUnretained is safe.
        let ctx = Unmanaged.passUnretained(self).toOpaque()

        InstallApplicationEventHandler(
            { (_, event, userData) -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hkID = EventHotKeyID()
                guard GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                ) == noErr else { return OSStatus(eventNotHandledErr) }

                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async { mgr.dispatch(id: hkID.id) }
                return noErr
            },
            GetApplicationEventTarget(),
            1,
            &spec,
            ctx,
            &eventHandlerRef
        )
    }

    private func dispatch(id: UInt32) {
        switch Action(rawValue: id) {
        case .start: viewModel?.startSimulation()
        case .stop:  viewModel?.stopSimulation()
        case .pause: viewModel?.togglePause()
        case .reset: viewModel?.resetStats()
        case .none:  break
        }
    }

    deinit { unregister() }
}
