public struct CourtID: Sendable, Hashable, Codable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw CourtListenerError.invalidIdentifier("CourtID cannot be blank")
        }
        self.rawValue = trimmed
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension CourtID: CustomStringConvertible {
    public var description: String { rawValue }
}

#if DEBUG
extension CourtID {
    public static let scotus = try! CourtID("scotus")
    public static let ca1 = try! CourtID("ca1")
    public static let ca9 = try! CourtID("ca9")
}
#endif
