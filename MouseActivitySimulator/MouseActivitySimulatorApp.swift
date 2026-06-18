import SwiftUI

@main
struct MouseActivitySimulatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Mouse Activity Simulator") {
            ContentView()
                .environmentObject(appDelegate.viewModel)
                .frame(minWidth: 460, idealWidth: 480, minHeight: 500, idealHeight: 560)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
