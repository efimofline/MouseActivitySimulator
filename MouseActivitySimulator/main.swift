// main.swift — классическая точка входа AppKit (macOS 10.15+).
// SwiftUI App/WindowGroup недоступны на 10.15, поэтому используем
// NSApplication + AppDelegate + NSHostingView.
import AppKit

let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
