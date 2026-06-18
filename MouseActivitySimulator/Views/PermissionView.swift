import SwiftUI

/// Shown when the app lacks Accessibility permission.
/// Uses macOS 10.15-compatible APIs only:
/// no SF Symbols, no markdown Text bold, no borderedProminent.
struct PermissionView: View {
    @EnvironmentObject var viewModel: SimulationViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Lock icon via emoji — Image(systemName:) requires macOS 11+
            Text("🔒")
                .font(.system(size: 72))

            VStack(spacing: 8) {
                Text("Accessibility Permission Required")
                    // .title2 requires macOS 11+; use explicit size
                    .font(.system(size: 22, weight: .semibold))

                Text("Mouse Activity Simulator needs Accessibility access to move the cursor and simulate clicks to keep your session active.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            // Step-by-step instructions
            VStack(alignment: .leading, spacing: 10) {
                step("1", "Click \"Open Settings\" below")
                step("2", "Go to Privacy & Security → Accessibility")
                step("3", "Enable Mouse Activity Simulator in the list")
                step("4", "Return here and click \"Check Again\"")
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 32)

            HStack(spacing: 14) {
                Button {
                    viewModel.checkPermission()
                } label: {
                    HStack(spacing: 4) { Text("↺"); Text("Check Again") }
                }
                .buttonStyle(BorderedButtonStyle())

                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    HStack(spacing: 4) { Text("⚙"); Text("Open Settings") }
                }
                .buttonStyle(BorderedButtonStyle())
            }

            Spacer()
        }
        .frame(minWidth: 460, minHeight: 460)
        .padding()
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.callout, design: .monospaced)).fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.18))
                .cornerRadius(12)
            Text(text).font(.callout)
        }
    }
}
