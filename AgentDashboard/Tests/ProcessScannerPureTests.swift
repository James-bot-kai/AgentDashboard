import XCTest
@testable import AgentDashboard

/// ProcessScanner 的纯函数(解析/判定)。nonisolated static,无需 actor。
final class ProcessScannerPureTests: XCTestCase {

    func testParseEtimeSeconds() {
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds("20"), 20)
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds("1:20"), 80)
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds("1:02:03"), 3723)
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds("1-02:03:04"), 1 * 86400 + 2 * 3600 + 3 * 60 + 4)
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds(""), 0)
        XCTAssertEqual(ProcessScanner.parseEtimeSeconds("garbage"), 0)
    }

    func testIsClaudeLine() {
        XCTAssertTrue(ProcessScanner.isClaudeLine("12345 ttys001 S 0.0 00:00 claude"))
        XCTAssertTrue(ProcessScanner.isClaudeLine("12345 ttys001 S 0.0 00:00 claude --resume abc"))
        XCTAssertFalse(ProcessScanner.isClaudeLine("12345 ttys001 S 0.0 00:00 claude --output-format stream-json"))
        XCTAssertFalse(ProcessScanner.isClaudeLine("12345 ttys001 S 0.0 00:00 claude bypassPermissions"))
        XCTAssertFalse(ProcessScanner.isClaudeLine("12345 ttys001 S 0.0 00:00 codex"))
    }

    func testIsCodexLine() {
        XCTAssertTrue(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 codex"))
        XCTAssertTrue(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 codex test"))
        XCTAssertTrue(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 node /usr/local/bin/codex"))
        XCTAssertFalse(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 codex app-server --listen stdio"))
        XCTAssertFalse(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 node_repl"))
        XCTAssertFalse(ProcessScanner.isCodexLine("12345 ttys001 S 0.0 00:00 claude"))
    }

    func testCpuFallbackStatus() {
        XCTAssertEqual(ProcessScanner.cpuFallbackStatus(cpu: 0, stat: "S"), .idle)
        XCTAssertEqual(ProcessScanner.cpuFallbackStatus(cpu: 5, stat: "S"), .busy)
        XCTAssertEqual(ProcessScanner.cpuFallbackStatus(cpu: 0, stat: "R"), .running)
        XCTAssertEqual(ProcessScanner.cpuFallbackStatus(cpu: 50, stat: "S"), .running)
    }
}
