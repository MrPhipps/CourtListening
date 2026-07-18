public enum DateGranularity: String, Codable, Sendable, Hashable, CaseIterable {
    case year = "%Y"
    case yearMonth = "%Y-%m"
    case fullDate = "%Y-%m-%d"
    case unknown = ""

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DateGranularity(rawValue: raw) ?? .unknown
    }
}
