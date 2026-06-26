import Foundation

enum HookType: String, Sendable {
    case preToolUse = "PreToolUse"
    case postToolUse = "PostToolUse"
    case postToolUseFailure = "PostToolUseFailure"
    case stop = "Stop"
    case userPromptSubmit = "UserPromptSubmit"
}

struct HookEvent: Sendable {
    let hookType: HookType
    let sessionId: String
    let toolName: String?
    let timestamp: Date

    init?(queryType: String, json: [String: Any]) {
        guard let hookType = HookType(rawValue: queryType) else { return nil }
        self.hookType = hookType
        self.timestamp = Date()

        self.sessionId = json["session_id"] as? String ?? ""
        guard !self.sessionId.isEmpty else { return nil }

        self.toolName = json["tool_name"] as? String
    }
}
