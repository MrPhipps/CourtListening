import Foundation
import CourtListeningCore

public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// The concrete transport implementation. Use `.live` in production, `.stubbed` or `.spy`
/// for tests, and `.failing` to exercise error-handling paths.
public enum CourtListenerTransport: HTTPTransport {
    case live
    case stubbed(responses: [URL: Data])
    case failing(NetworkError)
    case spy(capture: RequestCapture, responses: [URL: Data])

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        switch self {

        case .live:
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.unexpectedStatusCode(0)
            }
            return (data, http)

        case .stubbed(let responses):
            guard let url = request.url, let data = responses[url] else {
                throw NetworkError.unexpectedStatusCode(404)
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (data, response)

        case .failing(let error):
            throw error

        case .spy(let capture, let responses):
            await capture.record(request)
            guard let url = request.url, let data = responses[url] else {
                throw NetworkError.unexpectedStatusCode(404)
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (data, response)
        }
    }
}

/// Records URLRequests for later assertion in tests. Actor-isolated for safe concurrent access.
public actor RequestCapture: Sendable {
    public private(set) var capturedRequests: [URLRequest] = []

    public init() {}

    public func record(_ request: URLRequest) {
        capturedRequests.append(request)
    }

    public func reset() {
        capturedRequests.removeAll()
    }
}
