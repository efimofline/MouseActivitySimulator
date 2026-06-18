import SwiftUI

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
            Image(systemName: "cursorarrow.motionlines")
                .font(.title2)
                .foregroundColor(.accentColor)

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
            // Pulsing dot when running
            ZStack {
                if viewModel.isRunning && !viewModel.isPaused {
                    Circle().fill(viewModel.statusColor.opacity(0.3)).frame(width: 14, height: 14)
                        .scaleEffect(viewModel.isRunning ? 1.3 : 1)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                                   value: viewModel.isRunning)
                }
                Circle().fill(viewModel.statusColor).frame(width: 8, height: 8)
            }
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
            statCard("Uptime",  value: viewModel.formattedTime,    icon: "clock.fill")
            statCard("Moves",   value: "\(viewModel.totalMoves)",  icon: "arrow.up.and.down.and.arrow.left.and.right")
            statCard("Clicks",  value: "\(viewModel.totalClicks)", icon: "cursorarrow.click.fill")
        }
    }

    private func statCard(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.caption).foregroundColor(.secondary)
            Text(value).font(.system(.title3, design: .monospaced)).fontWeight(.semibold)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: Controls box

    private var controlsBox: some View {
        GroupBox("Simulation Controls") {
            VStack(spacing: 10) {
                Toggle("Enable Mouse Movement", isOn: $viewModel.config.isMouseMovementEnabled)
                Divider()
                Toggle("Enable Mouse Clicks",   isOn: $viewModel.config.isMouseClickEnabled)

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

    private var timingBox: some View {
        GroupBox("Timing & Distance") {
            VStack(spacing: 10) {
                labeledSlider("Min interval",  value: $viewModel.config.minInterval,
                              in: 1...60,   step: 1, format: { "\(Int($0)) s" })
                    .onChange(of: viewModel.config.minInterval) { v in
                        if v > viewModel.config.maxInterval { viewModel.config.maxInterval = v }
                    }

                labeledSlider("Max interval",  value: $viewModel.config.maxInterval,
                              in: 1...120,  step: 1, format: { "\(Int($0)) s" })
                    .onChange(of: viewModel.config.maxInterval) { v in
                        if v < viewModel.config.minInterval { viewModel.config.minInterval = v }
                    }

                Divider()

                labeledSlider("Min movement",  value: $viewModel.config.minMovement,
                              in: 1...50,   step: 1, format: { "\(Int($0)) px" })
                    .onChange(of: viewModel.config.minMovement) { v in
                        if v > viewModel.config.maxMovement { viewModel.config.maxMovement = v }
                    }

                labeledSlider("Max movement",  value: $viewModel.config.maxMovement,
                              in: 5...200,  step: 5, format: { "\(Int($0)) px" })
                    .onChange(of: viewModel.config.maxMovement) { v in
                        if v < viewModel.config.minMovement { viewModel.config.minMovement = v }
                    }
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

    // MARK: Hotkeys reference box

    private var hotkeysBox: some View {
        GroupBox("Global Hotkeys  (work system-wide)") {
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
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            if viewModel.isRunning {
                Button {
                    viewModel.togglePause()
                } label: {
                    Label(
                        viewModel.isPaused ? "Resume" : "Pause",
                        systemImage: viewModel.isPaused ? "play.fill" : "pause.fill"
                    )
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    viewModel.stopSimulation()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

            } else {
                Button {
                    viewModel.startSimulation()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
