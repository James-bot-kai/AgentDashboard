import XCTest
@testable import AgentDashboard

final class TokenStatsReaderTests: XCTestCase {

    private func transcript() -> String {
        let path = Bundle.module.path(forResource: "transcript", withExtension: "jsonl", subdirectory: "Fixtures/claude")
        XCTAssertNotNil(path, "missing claude transcript fixture")
        return path!
    }

    /// assistant 行的 message.usage 累加(user 行跳过)。
    func testAccumulateSumsAssistantUsage() {
        let reader = TokenStatsReader()
        let u = reader.accumulate(transcriptPath: transcript())
        XCTAssertEqual(u.inputTokens, 250)            // 100 + 150
        XCTAssertEqual(u.cacheCreationTokens, 50)     // 50 + 0
        XCTAssertEqual(u.cacheReadTokens, 500)        // 200 + 300
        XCTAssertEqual(u.outputTokens, 70)            // 30 + 40
    }
}
