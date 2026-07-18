public enum Gender: String, Codable, Sendable, Hashable, CaseIterable {
    case male = "m"
    case female = "f"
    case unspecified = ""

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Gender(rawValue: raw) ?? .unspecified
    }
}
