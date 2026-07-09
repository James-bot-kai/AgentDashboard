import XCTest
@testable import AgentDashboard

final class AgentInfoTests: XCTestCase {

    func testParseElapsedTime() {
        XCTAssertEqual(AgentInfo.parseElapsedTime("30s"), 30)
        XCTAssertEqual(AgentInfo.parseElapsedTime("2m30s"), 150)
        XCTAssertEqual(AgentInfo.parseElapsedTime("1h2m3s"), 3723)
        XCTAssertEqual(AgentInfo.parseElapsedTime("1d2h"), 1 * 86400 + 2 * 3600)
        XCTAssertEqual(AgentInfo.parseElapsedTime("2d"), 2 * 86400)
        XCTAssertEqual(AgentInfo.parseElapsedTime(""), 0)
        XCTAssertEqual(AgentInfo.parseElapsedTime("invalid"), 0)
    }
}
