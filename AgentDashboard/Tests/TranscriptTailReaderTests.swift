import XCTest
@testable import AgentDashboard

final class TranscriptTailReaderTests: XCTestCase {

    func testUnansweredAskUserQuestionIsConfirming() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("agent-dashboard-question-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: url) }

        let event: [String: Any] = [
            "type": "assistant",
            "message": [
                "content": [[
                    "type": "tool_use",
                    "name": "AskUserQuestion",
                    "id": "tool-1",
                    "input": ["question": "Continue?"]
                ]]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: event)
        try (data + Data("\n".utf8)).write(to: url)

        XCTAssertEqual(TranscriptTailReader().inferActivity(transcriptPath: url.path), .confirming)
    }
}
