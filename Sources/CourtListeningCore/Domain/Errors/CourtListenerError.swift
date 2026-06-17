import Foundation

public enum CourtListenerError: Error, Sendable, LocalizedError, Equatable {
    case invalidIdentifier(String)
    case invalidToken
    case unauthorized
    case forbidden
    case notFound(String)
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(statusCode: Int)
    case decodingFailed(String)
    case networkUnavailable
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidIdentifier(let message):
            return message
        case .invalidToken:
            return "API token must be at least 10 characters"
        case .unauthorized:
            return "Authentication required — provide a valid API token"
        case .forbidden:
            return "Access denied for this resource"
        case .notFound(let resource):
            return "Resource not found: \(resource)"
        case .rateLimited(let retry):
            if let retry { return "Rate limited — retry after \(Int(retry)) seconds" }
            return "Rate limited — please retry later"
        case .serverError(let code):
            return "Server error \(code)"
        case .decodingFailed(let detail):
            return "Failed to decode response: \(detail)"
        case .networkUnavailable:
            return "Network unavailable"
        case .unknown(let detail):
            return "Unexpected error: \(detail)"
        }
    }

    public static func == (lhs: CourtListenerError, rhs: CourtListenerError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidIdentifier(let a), .invalidIdentifier(let b)): return a == b
        case (.invalidToken, .invalidToken): return true
        case (.unauthorized, .unauthorized): return true
        case (.forbidden, .forbidden): return true
        case (.notFound(let a), .notFound(let b)): return a == b
        case (.rateLimited(let a), .rateLimited(let b)): return a == b
        case (.serverError(let a), .serverError(let b)): return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)): return a == b
        case (.networkUnavailable, .networkUnavailable): return true
        case (.unknown(let a), .unknown(let b)): return a == b
        default: return false
        }
    }
}
