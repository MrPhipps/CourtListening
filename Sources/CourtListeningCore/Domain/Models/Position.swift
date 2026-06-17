import Foundation

public struct Position: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: PositionID
    public let person: URL
    public let court: URL?
    public let positionType: String?
    public let jobTitle: String
    public let organization: String
    public let dateStart: String?
    public let dateGranularityStart: DateGranularity
    public let dateRetirement: String?
    public let termination: String
    public let voterAffiliation: String?
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case person
        case court
        case positionType = "position_type"
        case jobTitle = "job_title"
        case organization = "organization_name"
        case dateStart = "date_start"
        case dateGranularityStart = "date_granularity_start"
        case dateRetirement = "date_retirement"
        case termination = "termination_reason"
        case voterAffiliation = "how_selected"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }
}
