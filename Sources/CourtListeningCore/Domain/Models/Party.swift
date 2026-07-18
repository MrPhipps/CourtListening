import Foundation

public struct Party: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: PartyID
    public let name: String
    public let extraInfo: String
    public let dateCreated: Date
    public let dateModified: Date

    // NOTE: The live /parties/ response has NO top-level `docket` or `date_terminated`.
    // Both are nested under `party_types[]` (a party can belong to multiple dockets with a
    // per-docket role and termination date). The docket is already known by the caller
    // (parties are stored under DocketID in the model), so it isn't decoded here.
    // `party_types` will be modeled in Phase 3 when docket-detail surfaces the party role.
    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case name
        case extraInfo = "extra_info"
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
            name: "John Doe",
            extraInfo: "",
            dateCreated: Date(timeIntervalSince1970: 1_616_025_600),
            dateModified: Date(timeIntervalSince1970: 1_616_025_600)
        )
    }
}
#endif
