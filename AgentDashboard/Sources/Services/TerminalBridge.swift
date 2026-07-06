import Foundation

/// Routes click-to-jump to the bridge matching the agent's host terminal.
/// `.unknown` falls back to iTerm2 to preserve prior behavior.
enum TerminalBridge {
    static func activate(tty: String, app: TerminalApp) {
        switch app {
        case .terminal:
            TerminalAppBridge.activateSession(tty: tty)
        case .iTerm2, .unknown:
            ITerm2Bridge.activateSession(tty: tty)
        }
    }
}
