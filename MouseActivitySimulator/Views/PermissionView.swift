import SwiftUI

/// Shown when the app lacks Accessibility permission.
struct PermissionView: View {
    @EnvironmentObject var viewModel: SimulationViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundColor(.orange)
                .symbolRenderingMode(.multicolor)

            VStack(spacing: 8) {
                Text("Accessibility Permission Required")
                    .font(.title2).fontWeight(.semibold)

                Text("""
                    Mouse Activity Simulator needs Accessibility access \
                    to move the cursor and simulate clicks on your behalf.
                    """)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            // Step-by-step instructions
            VStack(alignment: .leading, spacing: 10) {
                step("1", text: "Click **Open Settings** below")
                step("2", text: "Go to **Privacy & Security → Accessibility**")
                step("3", text: "Enable **Mouse Activity Simulator** in the list")
                step("4", text: "Return here and click **Check Again**")
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal, 32)

            HStack(spacing: 14) {
                Button {
                    viewModel.checkPermission()
                } label: {
                    Label("Check Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.openAccessibilitySettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .frame(minWidth: 460, minHeight: 460)
        .padding()
    }

    @ViewBuilder
    private func step(_ number: String, text: LocalizedStringKey) -> some View {
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
