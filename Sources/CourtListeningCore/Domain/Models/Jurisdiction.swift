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
}
