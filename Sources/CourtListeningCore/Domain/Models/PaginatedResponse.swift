import Foundation

public struct PaginatedResponse<Resource: Codable & Sendable>: Codable, Sendable {
    public let count: ResponseCount
    public let next: URL?
    public let previous: URL?
    public let results: [Resource]

    public var nextCursor: String? {
        next.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
            .flatMap { $0.queryItems?.first(where: { $0.name == "cursor" })?.value }
    }

    public var nextPage: Int? {
        next.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
            .flatMap { $0.queryItems?.first(where: { $0.name == "page" })?.value }
            .flatMap { Int($0) }
    }
}
