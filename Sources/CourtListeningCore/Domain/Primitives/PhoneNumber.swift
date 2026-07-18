import Foundation

/// A validated, normalised phone number. Stored as digits and leading '+' only.
/// Requires at least 7 digits after stripping non-numeric characters.
public struct PhoneNumber: Sendable, Codable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) throws {
        let hasLeadingPlus = rawValue.first == "+"
        let digits = rawValue.filter(\.isNumber)
        guard digits.count >= 7
        else { throw CourtListenerError.invalidIdentifier("PhoneNumber must contain at least 7 digits") }
        self.rawValue = (hasLeadingPlus ? "+" : "") + digits
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        try self.init(raw)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
