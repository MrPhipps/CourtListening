public struct APIToken: Sendable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        guard rawValue.count >= 10 else {
            throw CourtListenerError.invalidToken
        }
        self.rawValue = rawValue
    }

    public var authorizationHeaderValue: String {
        "Token \(rawValue)"
    }
}
