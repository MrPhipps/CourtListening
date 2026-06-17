import Foundation

public struct Party: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: PartyID
    public let docket: URL
    public let name: String
    public let extraInfo: String
    public let dateTerminated: String?
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case docket
        case name
        case extraInfo = "extra_info"
        case dateTerminated = "date_terminated"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }
}

#if DEBUG
extension Party {
    public enum TestData {
        public static let petitioner = Party(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/parties/4001/")!,
            id: try! PartyID(4001),
            docket: URL(string: "https://www.courtlistener.com/api/rest/v4/dockets/1001/")!,
            name: "John Doe",
            extraInfo: "",
            dateTerminated: nil,
            dateCreated: Date(timeIntervalSince1970: 1_616_025_600),
            dateModified: Date(timeIntervalSince1970: 1_616_025_600)
        )
    }
}
#endif
