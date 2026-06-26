import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.lucky.AgentDashboard", category: "HookServer")

class HookServer {
    private var listener: NWListener?
    private let port: UInt16 = 8765
    var onEvent: ((@Sendable (HookEvent) -> Void))?

    func start() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            logger.error("Invalid port: \(self.port)")
            return
        }

        do {
            listener = try NWListener(using: params, on: nwPort)
        } catch {
            logger.warning("HookServer failed to create listener: \(error.localizedDescription)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                logger.info("HookServer listening on 127.0.0.1:8765")
            case .failed(let error):
                logger.warning("HookServer listener failed: \(error.localizedDescription)")
            case .cancelled:
                logger.info("HookServer stopped")
            default:
                break
            }
        }

        listener?.start(queue: .main)
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        receiveData(on: connection, accumulated: Data())
    }

    private func receiveData(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else {
                connection.cancel()
                return
            }

            var buffer = accumulated
            if let content = content {
                buffer.append(content)
            }

            if isComplete || error != nil || self.hasCompleteHTTPRequest(buffer) {
                self.processRequest(data: buffer, connection: connection)
            } else {
                self.receiveData(on: connection, accumulated: buffer)
            }
        }
    }

    private func hasCompleteHTTPRequest(_ data: Data) -> Bool {
        guard let str = String(data: data, encoding: .utf8) else { return false }
        guard let headerEnd = str.range(of: "\r\n\r\n") else { return false }

        let headers = String(str[..<headerEnd.lowerBound])
        let bodyStart = str[headerEnd.upperBound...]

        if let clRange = headers.range(of: "Content-Length: ", options: .caseInsensitive) {
            let afterCL = headers[clRange.upperBound...]
            let lengthStr = afterCL.prefix(while: { $0.isNumber })
            if let contentLength = Int(lengthStr) {
                return bodyStart.utf8.count >= contentLength
            }
        }

        return true
    }

    private func processRequest(data: Data, connection: NWConnection) {
        defer { sendResponse(connection: connection) }

        guard let request = String(data: data, encoding: .utf8) else { return }

        let (method, path, body) = parseHTTPRequest(request)
        guard method == "POST", path.hasPrefix("/hook") else { return }

        let queryType = extractQueryParam(path: path, key: "type") ?? ""
        guard !queryType.isEmpty else { return }

        guard let bodyData = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            return
        }

        if let event = HookEvent(queryType: queryType, json: json) {
            onEvent?(event)
        }
    }

    private func parseHTTPRequest(_ raw: String) -> (method: String, path: String, body: String) {
        let headerBodySplit = raw.components(separatedBy: "\r\n\r\n")
        let body = headerBodySplit.count > 1 ? headerBodySplit[1] : ""

        let firstLine = raw.components(separatedBy: "\r\n").first ?? ""
        let parts = firstLine.components(separatedBy: " ")
        let method = parts.count > 0 ? parts[0] : ""
        let path = parts.count > 1 ? parts[1] : ""

        return (method, path, body)
    }

    private func extractQueryParam(path: String, key: String) -> String? {
        guard let queryStart = path.firstIndex(of: "?") else { return nil }
        let query = String(path[path.index(after: queryStart)...])
        let pairs = query.components(separatedBy: "&")
        for pair in pairs {
            let kv = pair.components(separatedBy: "=")
            if kv.count == 2, kv[0] == key {
                return kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return nil
    }

    private func sendResponse(connection: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        let data = response.data(using: .utf8) ?? Data()
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
