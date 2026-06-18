import Foundation
import CoreGraphics
import AppKit

/// Generates synthetic mouse events on a private background queue.
///
/// Coordinate notes
/// ────────────────
/// • NSEvent.mouseLocation  → AppKit space (origin bottom-left of main screen, Y up)
/// • CGEvent mouse position → CG space     (origin top-left  of main screen, Y down)
/// Conversion: cgY = screenHeight − nsY
final class MouseSimulationService {

    // MARK: - Public interface

    var config: SimulationConfig = SimulationConfig()

    /// Called from background queue after every move.
    var onMovePerformed:  (() -> Void)?
    /// Called from background queue after every click.
    var onClickPerformed: (() -> Void)?

    private(set) var isRunning = false
    private(set) var isPaused  = false

    // MARK: - Private

    private var timer: DispatchSourceTimer?
    private let q = DispatchQueue(label: "com.mouseactivity.sim", qos: .userInitiated)

    // MARK: - Control

    func start() {
        guard !isRunning, checkAccessibilityPermission() else { return }
        isRunning = true
        isPaused  = false
        scheduleNext()
    }

    func stop() {
        isRunning = false
        isPaused  = false
        cancelTimer()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        cancelTimer()
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        scheduleNext()
    }

    // MARK: - Timer

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    private func scheduleNext() {
        guard isRunning, !isPaused else { return }

        let delay = Double.random(in: config.minInterval...config.maxInterval)
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + delay, leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in self?.performAction() }
        t.resume()
        timer = t
    }

    // MARK: - Simulation actions

    private func performAction() {
        guard isRunning, !isPaused else { return }

        if config.isMouseMovementEnabled {
            moveMouse()
            onMovePerformed?()
        }

        if config.isMouseClickEnabled {
            if Double.random(in: 0...1) < config.clickProbability {
                // Brief natural pause before clicking
                Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.4))
                performClick()
                onClickPerformed?()
            }
        }

        scheduleNext()
    }

    // MARK: - Mouse movement

    private func moveMouse() {
        let origin = currentPositionCG()
        let bounds = screenBoundsCG()

        var dx = CGFloat.random(in: -CGFloat(config.maxMovement)...CGFloat(config.maxMovement))
        var dy = CGFloat.random(in: -CGFloat(config.maxMovement)...CGFloat(config.maxMovement))

        // Ensure the displacement meets the minimum distance
        let dist = (dx * dx + dy * dy).squareRoot()
        if dist > 0, dist < CGFloat(config.minMovement) {
            let scale = CGFloat(config.minMovement) / dist
            dx *= scale
            dy *= scale
        }

        // Clamp to screen (leave 10 px margin on each edge; 30 px at top for menu bar)
        let newX = min(max(origin.x + dx, bounds.minX + 10), bounds.maxX - 10)
        let newY = min(max(origin.y + dy, bounds.minY + 30), bounds.maxY - 10)

        smoothMoveCursor(from: origin, to: CGPoint(x: newX, y: newY))
    }

    /// Animates the cursor along a cubic ease-in-out curve for a natural look.
    private func smoothMoveCursor(from src: CGPoint, to dst: CGPoint) {
        let steps       = Int.random(in: 12...30)
        let stepDelay   = 0.014 // ≈70 fps

        for i in 1...steps {
            let t      = Double(i) / Double(steps)
            // Cubic ease-in-out: f(t) = t<0.5 ? 4t³ : 1 − (−2t+2)³/2
            let eased  = t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
            let x      = src.x + (dst.x - src.x) * CGFloat(eased)
            let y      = src.y + (dst.y - src.y) * CGFloat(eased)

            postEvent(type: .mouseMoved, at: CGPoint(x: x, y: y))
            Thread.sleep(forTimeInterval: stepDelay)
        }
    }

    // MARK: - Mouse click

    private func performClick() {
        let pos = currentPositionCG()
        postEvent(type: .leftMouseDown, at: pos)
        Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.12))
        postEvent(type: .leftMouseUp,   at: pos)
    }

    // MARK: - CGEvent helpers

    private func postEvent(type: CGEventType, at point: CGPoint) {
        guard let e = CGEvent(
            mouseEventSource: nil,
            mouseType:        type,
            mouseCursorPosition: point,
            mouseButton:      .left
        ) else { return }
        e.post(tap: .cghidEventTap)
    }

    // MARK: - Coordinate helpers

    private func currentPositionCG() -> CGPoint {
        let ns = NSEvent.mouseLocation
        let h  = NSScreen.main?.frame.height ?? 1080
        return CGPoint(x: ns.x, y: h - ns.y)
    }

    private func screenBoundsCG() -> CGRect {
        guard let s = NSScreen.main else { return CGRect(x: 0, y: 0, width: 1920, height: 1080) }
        return CGRect(x: 0, y: 0, width: s.frame.width, height: s.frame.height)
    }

    // MARK: - Permissions

    func checkAccessibilityPermission() -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    func requestAccessibilityPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }
}
