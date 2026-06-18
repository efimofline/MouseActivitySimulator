import Foundation

/// All tunable parameters for the mouse activity simulation.
struct SimulationConfig {
    var isMouseMovementEnabled: Bool   = true
    var isMouseClickEnabled: Bool      = true

    /// Minimum seconds between simulation events.
    var minInterval: Double = 5.0
    /// Maximum seconds between simulation events.
    var maxInterval: Double = 30.0

    /// Minimum per-move displacement in pixels.
    var minMovement: Double = 5.0
    /// Maximum per-move displacement in pixels.
    var maxMovement: Double = 50.0

    /// Probability [0–1] that a given action cycle also fires a click.
    var clickProbability: Double = 0.15
}
