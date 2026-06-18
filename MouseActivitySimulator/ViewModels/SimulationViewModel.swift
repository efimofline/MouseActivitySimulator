import SwiftUI
import Combine

/// Central MVVM view-model.  All @Published mutations happen on the main thread.
final class SimulationViewModel: ObservableObject {

    // MARK: - Published state

    @Published var isRunning:  Bool   = false
    @Published var isPaused:   Bool   = false
    @Published var hasPermission: Bool = false

    @Published var elapsedSeconds: TimeInterval = 0
    @Published var totalMoves:  Int = 0
    @Published var totalClicks: Int = 0

    @Published var config = SimulationConfig()

    // MARK: - Derived

    var statusText: String {
        guard hasPermission else { return "No Permission" }
        if isRunning { return isPaused ? "Paused" : "Running" }
        return "Stopped"
    }

    var statusColor: Color {
        guard hasPermission else { return .red }
        if isRunning { return isPaused ? .orange : .green }
        return .secondary
    }

    var formattedTime: String {
        let h = Int(elapsedSeconds) / 3600
        let m = (Int(elapsedSeconds) % 3600) / 60
        let s = Int(elapsedSeconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Private

    private let service = MouseSimulationService()
    private var uptimeTimer: Timer?
    private var sessionStart: Date?
    private var accumulated: TimeInterval = 0

    // MARK: - Init

    init() {
        service.onMovePerformed  = { [weak self] in DispatchQueue.main.async { self?.totalMoves  += 1 } }
        service.onClickPerformed = { [weak self] in DispatchQueue.main.async { self?.totalClicks += 1 } }
    }

    // MARK: - Permission

    func checkPermission() {
        hasPermission = service.checkAccessibilityPermission()
    }

    func openAccessibilitySettings() {
        service.requestAccessibilityPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Simulation control

    func startSimulation() {
        checkPermission()
        guard hasPermission else { openAccessibilitySettings(); return }

        service.config = config
        service.start()
        isRunning = true
        isPaused  = false
        beginUptime()
    }

    func stopSimulation() {
        service.stop()
        isRunning = false
        isPaused  = false
        stopUptime()
    }

    func togglePause() {
        guard isRunning else { return }
        if isPaused {
            service.resume()
            isPaused = false
            resumeUptime()
        } else {
            service.pause()
            isPaused = true
            pauseUptime()
        }
    }

    func resetStats() {
        totalMoves    = 0
        totalClicks   = 0
        elapsedSeconds = 0
        accumulated   = 0
        sessionStart  = (isRunning && !isPaused) ? Date() : nil
    }

    // MARK: - Uptime tracking

    private func beginUptime() {
        accumulated  = 0
        sessionStart = Date()
        startTimer()
    }

    private func stopUptime() {
        uptimeTimer?.invalidate()
        uptimeTimer = nil
        sessionStart = nil
    }

    private func pauseUptime() {
        if let s = sessionStart { accumulated += Date().timeIntervalSince(s) }
        sessionStart = nil
        uptimeTimer?.invalidate()
        uptimeTimer = nil
    }

    private func resumeUptime() {
        sessionStart = Date()
        startTimer()
    }

    private func startTimer() {
        uptimeTimer?.invalidate()
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let s = self.sessionStart else { return }
            self.elapsedSeconds = self.accumulated + Date().timeIntervalSince(s)
        }
    }
}
