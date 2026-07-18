public enum Jurisdiction: String, Codable, Sendable, Hashable, CaseIterable {
    case federal = "F"
    case federalSpecial = "FS"
    case militaryAppellate = "MA"
    case stateSupreme = "S"
    case stateAppellate = "SA"
    case stateTrial = "ST"
    case stateLower = "SL"
    case territory = "T"
    case territorial = "TT"
    case tribal = "TR"
    case bankruptcy = "FB"
    case bankruptcyPanel = "FBP"
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Jurisdiction(rawValue: raw) ?? .unknown
    }

    /// Human-readable label for display (the raw values are terse API codes like "F").
    public var displayName: String {
        switch self {
        case .federal: return "Federal"
        case .federalSpecial: return "Federal Special"
        case .militaryAppellate: return "Military Appellate"
        case .stateSupreme: return "State Supreme"
        case .stateAppellate: return "State Appellate"
        case .stateTrial: return "State Trial"
        case .stateLower: return "State Lower"
        case .territory: return "Territory"
        case .territorial: return "Territorial"
        case .tribal: return "Tribal"
        case .bankruptcy: return "Bankruptcy"
        case .bankruptcyPanel: return "Bankruptcy Panel"
        case .unknown: return "Unknown"
        }
    }
}
