import XCTest
@testable import AgentDashboard

final class HookEventTests: XCTestCase {

    func testParsesPermissionRequest() {
        let event = HookEvent(queryType: "PermissionRequest", json: [
            "session_id": "session-1",
            "tool_name": "Bash"
        ])

        XCTAssertEqual(event?.hookType, .permissionRequest)
        XCTAssertEqual(event?.sessionId, "session-1")
        XCTAssertEqual(event?.toolName, "Bash")
    }

    func testParsesNotificationType() {
        let event = HookEvent(queryType: "Notification", json: [
            "session_id": "session-1",
            "message": "Claude needs your permission",
            "notification_type": "permission_prompt"
        ])

        XCTAssertEqual(event?.hookType, .notification)
        XCTAssertEqual(event?.notificationType, "permission_prompt")
    }

    func testParsesTranscriptPath() {
        let event = HookEvent(queryType: "PreToolUse", json: [
            "session_id": "session-1",
            "tool_name": "Read",
            "transcript_path": "/Users/x/.claude/projects/-Users-x-proj/abc.jsonl"
        ])

        XCTAssertEqual(event?.transcriptPath, "/Users/x/.claude/projects/-Users-x-proj/abc.jsonl")
    }
}
