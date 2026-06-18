import SwiftUI
import Combine

/// Root view — routes to the permission screen or the main simulator UI.
struct ContentView: View {
    @EnvironmentObject var viewModel: SimulationViewModel

    var body: some View {
        Group {
            if viewModel.hasPermission {
                SimulatorView()
            } else {
                PermissionView()
            }
        }
        .onAppear { viewModel.checkPermission() }
    }
}

// MARK: - Main simulator view

struct SimulatorView: View {
    @EnvironmentObject var viewModel: SimulationViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(spacing: 18) {
                    statsRow
                    controlsBox
                    timingBox
                    hotkeysBox
                }
                .padding(20)
            }

            Divider()
            actionBar
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            // Unicode mouse icon — Image(systemName:) requires macOS 11+
            Text("🖱")
                .font(.system(size: 22)) // .title2 requires macOS 11+

            VStack(alignment: .leading, spacing: 2) {
                Text("Mouse Activity Simulator").font(.headline)
                Text("macOS activity keeper").font(.caption).foregroundColor(.secondary)
            }

            Spacer()
            statusBadge
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(viewModel.statusColor).frame(width: 8, height: 8)
            Text(viewModel.statusText)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(viewModel.statusColor)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(viewModel.statusColor.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard("Uptime",  value: viewModel.formattedTime,    symbol: "⏱")
            statCard("Moves",   value: "\(viewModel.totalMoves)",  symbol: "⇅")
            statCard("Clicks",  value: "\(viewModel.totalClicks)", symbol: "⌖")
        }
    }

    private func statCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Text(symbol).font(.caption).foregroundColor(.secondary)
            Text(value)
                // .title3 requires macOS 11+; use explicit size instead
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
            Text(title)
                // .caption2 requires macOS 11+; use explicit size instead
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: Controls box
    // GroupBox("string") init requires macOS 12+; use label: Text(...) for 10.15

    private var controlsBox: some View {
        GroupBox(label: Text("Simulation Controls").font(.headline)) {
            VStack(spacing: 10) {
                Toggle("Enable Mouse Movement",
                       isOn: $viewModel.config.isMouseMovementEnabled)
                Divider()
                Toggle("Enable Mouse Clicks",
                       isOn: $viewModel.config.isMouseClickEnabled)

                if viewModel.config.isMouseClickEnabled {
                    labeledSlider(
                        "Click probability",
                        value:  $viewModel.config.clickProbability,
                        in:     0.05...0.50,
                        step:   0.05,
                        format: { "\(Int($0 * 100))%" }
                    )
                }
            }
            .padding(4)
        }
    }

    // MARK: Timing box
    // onChange(of:perform:) requires macOS 11+.
    // Use custom Bindings that clamp related values on set instead.

    private var minIntervalBinding: Binding<Double> {
        Binding(
            get: { viewModel.config.minInterval },
            set: { v in
                viewModel.config.minInterval = v
                if v > viewModel.config.maxInterval { viewModel.config.maxInterval = v }
            }
        )
    }

    private var maxIntervalBinding: Binding<Double> {
        Binding(
            get: { viewModel.config.maxInterval },
            set: { v in
                viewModel.config.maxInterval = v
                if v < viewModel.config.minInterval { viewModel.config.minInterval = v }
            }
        )
    }

    private var minMovementBinding: Binding<Double> {
        Binding(
            get: { viewModel.config.minMovement },
            set: { v in
                viewModel.config.minMovement = v
                if v > viewModel.config.maxMovement { viewModel.config.maxMovement = v }
            }
        )
    }

    private var maxMovementBinding: Binding<Double> {
        Binding(
            get: { viewModel.config.maxMovement },
            set: { v in
                viewModel.config.maxMovement = v
                if v < viewModel.config.minMovement { viewModel.config.minMovement = v }
            }
        )
    }

    private var timingBox: some View {
        GroupBox(label: Text("Timing & Distance").font(.headline)) {
            VStack(spacing: 10) {
                labeledSlider("Min interval", value: minIntervalBinding,
                              in: 1...60,  step: 1, format: { "\(Int($0)) s" })
                labeledSlider("Max interval", value: maxIntervalBinding,
                              in: 1...120, step: 1, format: { "\(Int($0)) s" })
                Divider()
                labeledSlider("Min movement", value: minMovementBinding,
                              in: 1...50,  step: 1, format: { "\(Int($0)) px" })
                labeledSlider("Max movement", value: maxMovementBinding,
                              in: 5...200, step: 5, format: { "\(Int($0)) px" })
            }
            .padding(4)
        }
    }

    private func labeledSlider(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(title).font(.callout)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 64, alignment: .trailing)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    // MARK: Hotkeys box

    private var hotkeysBox: some View {
        GroupBox(label: Text("Global Hotkeys  (work system-wide)").font(.headline)) {
            VStack(spacing: 6) {
                hotkeyRow("⌃⌥⌘S", "Start simulation")
                hotkeyRow("⌃⌥⌘X", "Stop  simulation")
                hotkeyRow("⌃⌥⌘P", "Pause / Resume")
                hotkeyRow("⌃⌥⌘R", "Reset statistics")
            }
            .padding(4)
        }
    }

    private func hotkeyRow(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 10) {
            Text(keys)
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(NSColor.controlColor))
                .cornerRadius(5)
            Text(label).font(.callout).foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: Action bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.resetStats()
            } label: {
                HStack(spacing: 4) { Text("↺"); Text("Reset") }
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.secondary)

            Spacer()

            if viewModel.isRunning {
                Button {
                    viewModel.togglePause()
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.isPaused ? "▶" : "⏸")
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                    }
                }
                .buttonStyle(BorderedButtonStyle())

                Button {
                    viewModel.stopSimulation()
                } label: {
                    HStack(spacing: 4) { Text("■"); Text("Stop") }
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.red)

            } else {
                Button {
                    viewModel.startSimulation()
                } label: {
                    HStack(spacing: 6) { Text("▶"); Text("Start") }
                        .frame(minWidth: 80)
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
