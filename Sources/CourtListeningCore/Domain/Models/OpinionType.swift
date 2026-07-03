public enum OpinionType: String, Codable, Sendable, Hashable, CaseIterable {
    case combined = "010combined"
    case unanimous = "015unamimous"
    case lead = "020lead"
    case plurality = "025plurality"
    case concurrence = "030concurrence"
    case concurrenceInPart = "035concurrenceinpart"
    case dissent = "040dissent"
    case addendum = "050addendum"
    case remittitur = "060remittitur"
    case rehearing = "070rehearing"
    case onMerits = "080onthemerits"
    case onMotionToStrike = "090onmotiontostrike"
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OpinionType(rawValue: raw) ?? .unknown
    }
}
