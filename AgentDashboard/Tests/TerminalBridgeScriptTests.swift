import XCTest
@testable import AgentDashboard

final class TerminalBridgeScriptTests: XCTestCase {
    func testITermScriptSelectsSessionTabAndWindow() throws {
        let script = try XCTUnwrap(ITerm2Bridge.activationScript(tty: "ttys008"))

        XCTAssertTrue(script.contains("tty of s is \"/dev/ttys008\""))
        XCTAssertTrue(script.contains("tell s to select"))
        XCTAssertTrue(script.contains("tell t to select"))
        XCTAssertTrue(script.contains("tell w to select"))
    }

    func testTerminalScriptSelectsTabAndFrontmostWindow() throws {
        let script = try XCTUnwrap(TerminalAppBridge.activationScript(tty: "/dev/ttys005"))

        XCTAssertTrue(script.contains("tTTY is \"ttys005\""))
        XCTAssertTrue(script.contains("tTTY is \"/dev/ttys005\""))
        XCTAssertTrue(script.contains("set selected of t to true"))
        XCTAssertTrue(script.contains("set frontmost of w to true"))
    }

    func testTTYInjectionIsRejected() {
        XCTAssertNil(ITerm2Bridge.activationScript(tty: "ttys008\" & do shell script \"id"))
        XCTAssertNil(TerminalAppBridge.activationScript(tty: "ttys005; rm -rf /"))
    }
}
