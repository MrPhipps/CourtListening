// Integer-backed identifiers for CourtListener resources.
// All validate that the underlying value is positive (> 0).

public struct DocketID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("DocketID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct OpinionID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("OpinionID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct ClusterID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("ClusterID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct PersonID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("PersonID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct PartyID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("PartyID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct AttorneyID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("AttorneyID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct PositionID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("PositionID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct AudioID: Sendable, Hashable, Codable {
    public let rawValue: Int

    public init(_ rawValue: Int) throws {
        guard rawValue > 0 else {
            throw CourtListenerError.invalidIdentifier("AudioID must be positive, got \(rawValue)")
        }
        self.rawValue = rawValue
    }

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Int.self)
        try self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - CustomStringConvertible

extension DocketID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension OpinionID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension ClusterID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension PersonID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension PartyID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension AttorneyID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension PositionID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
extension AudioID: CustomStringConvertible { public var description: String { "\(rawValue)" } }
