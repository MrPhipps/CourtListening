import Foundation

public enum NetworkError: Error, Sendable, LocalizedError {
    case invalidURL(String)
    case requestFailed(URLError)
    case unexpectedStatusCode(Int)
    case noData

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .requestFailed(let error):
            return error.localizedDescription
        case .unexpectedStatusCode(let code):
            return "Unexpected HTTP \(code)"
        case .noData:
            return "Empty response body"
        }
    }
}
