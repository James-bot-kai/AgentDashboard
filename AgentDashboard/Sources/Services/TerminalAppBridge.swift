import Foundation
import os

private let logger = Logger(subsystem: "com.lucky.AgentDashboard", category: "TerminalAppBridge")

/// Activates the Terminal.app tab bound to a given tty.
/// Both the bare (`ttysNNN`) and `/dev/`-prefixed forms are compared, since
/// the exact value returned by `tty of t` is not guaranteed across versions.
/// Only invoked when the agent was detected as running under Terminal.app —
/// `tell application "Terminal"` would otherwise launch the app.
enum TerminalAppBridge {
    private static let ttyPattern = try! NSRegularExpression(pattern: #"^(/dev/)?ttys\d+$"#)

    static func activateSession(tty: String) {
        guard isValidTTY(tty) else {
            logger.error("Invalid tty format rejected: \(tty)")
            return
        }

        let devicePath = tty.hasPrefix("/dev/") ? tty : "/dev/\(tty)"
        let bareTTY = tty.hasPrefix("/dev/") ? String(tty.dropFirst(5)) : tty

        let script = """
        tell application "Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    set tTTY to tty of t
                    if tTTY is "\(bareTTY)" or tTTY is "\(devicePath)" then
                        set selected of t to true
                        tell w
                            set index to 1
                        end tell
                        activate
                        return "ok"
                    end if
                end repeat
            end repeat
            return "not_found"
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let outPipe = Pipe()
            let errPipe = Pipe()

            process.standardOutput = outPipe
            process.standardError = errPipe
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            do {
                try process.run()
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus != 0 {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? "unknown"
                    logger.error("osascript failed (exit \(process.terminationStatus)): \(errMsg)")
                } else if output == "not_found" {
                    logger.info("Terminal.app session not found for tty: \(tty)")
                } else {
                    logger.debug("Terminal.app session activated for tty: \(tty)")
                }
            } catch {
                logger.error("Failed to launch osascript: \(error.localizedDescription)")
            }
        }
    }

    private static func isValidTTY(_ tty: String) -> Bool {
        let range = NSRange(tty.startIndex..., in: tty)
        return ttyPattern.firstMatch(in: tty, range: range) != nil
    }
}
