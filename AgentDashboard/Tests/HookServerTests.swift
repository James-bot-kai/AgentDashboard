import XCTest
@testable import AgentDashboard

final class HookServerTests: XCTestCase {

    func testCompleteRequest() {
        let body = #"{"session_id":"s1"}"#
        let request = "POST /hook?type=Stop HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        XCTAssertEqual(HookServer.requestReadState(Data(request.utf8)), .complete)
    }

    func testIncompleteBody() {
        let request = "POST /hook?type=Stop HTTP/1.1\r\nContent-Length: 10\r\n\r\n{}"
        XCTAssertEqual(HookServer.requestReadState(Data(request.utf8)), .incomplete)
    }

    func testMissingContentLengthIsRejected() {
        let request = "POST /hook?type=Stop HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n{}"
        XCTAssertEqual(
            HookServer.requestReadState(Data(request.utf8)),
            .rejected(status: "411 Length Required")
        )
    }

    func testOversizedBodyIsRejectedWithoutReceivingIt() {
        let request = "POST /hook?type=Stop HTTP/1.1\r\nContent-Length: \(HookServer.maxBodyBytes + 1)\r\n\r\n"
        XCTAssertEqual(
            HookServer.requestReadState(Data(request.utf8)),
            .rejected(status: "413 Payload Too Large")
        )
    }

    func testOversizedHeaderIsRejected() {
        let request = Data(repeating: 0x41, count: HookServer.maxHeaderBytes + 1)
        XCTAssertEqual(
            HookServer.requestReadState(request),
            .rejected(status: "431 Request Header Fields Too Large")
        )
    }
}
