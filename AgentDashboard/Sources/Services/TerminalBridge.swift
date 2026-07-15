import AppKit

/// Routes click-to-jump to the bridge matching the agent's host terminal.
/// `.unknown` falls back to iTerm2 to preserve prior behavior.
enum TerminalBridge {
    @MainActor
    static func activate(tty: String, app: TerminalApp) {
        yieldActivation(to: app)
        switch app {
        case .terminal:
            TerminalAppBridge.activateSession(tty: tty)
        case .iTerm2, .unknown:
            ITerm2Bridge.activateSession(tty: tty)
        }
    }

    /// AgentDashboard 的菜单栏 popover 可能仍持有激活权。先明确把激活权让给
    /// 目标终端，再由 AppleScript 选择具体窗口，可避免跨 Space 时首次点击只更新
    /// 终端内部 current window、第二次点击才真正切换。
    @MainActor
    private static func yieldActivation(to app: TerminalApp) {
        let bundleIdentifier: String
        switch app {
        case .terminal:
            bundleIdentifier = "com.apple.Terminal"
        case .iTerm2, .unknown:
            bundleIdentifier = "com.googlecode.iterm2"
        }

        guard let target = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return }

        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: target)
        } else {
            NSApp.deactivate()
        }
    }
}
