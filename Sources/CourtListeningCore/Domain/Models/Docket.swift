import Foundation

public struct Docket: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: DocketID
    public let caseName: String
    public let caseNameShort: String
    public let caseNameFull: String
    public let docketNumber: String
    public let courtID: CourtID
    public let court: URL
    public let dateFiled: String?
    public let dateTerminated: String?
    public let dateLastFiling: String?
    public let dateCreated: Date
    public let dateModified: Date
    public let assignedToStr: String
    public let referredToStr: String
    public let cause: String
    public let natureOfSuit: String
    public let jurisdictionType: String
    public let blocked: Bool
    public let slug: String
    public let absoluteURL: String
    public let clusters: [URL]
    public let tags: [URL]

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case caseName = "case_name"
        case caseNameShort = "case_name_short"
        case caseNameFull = "case_name_full"
        case docketNumber = "docket_number"
        case courtID = "court_id"
        case court
        case dateFiled = "date_filed"
        case dateTerminated = "date_terminated"
        case dateLastFiling = "date_last_filing"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case assignedToStr = "assigned_to_str"
        case referredToStr = "referred_to_str"
        case cause
        case natureOfSuit = "nature_of_suit"
        case jurisdictionType = "jurisdiction_type"
        case blocked
        case slug
        case absoluteURL = "absolute_url"
        case clusters
        case tags
    }
}

#if DEBUG
extension Docket {
    public enum TestData {
        public static let sampleDocket = Docket(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/dockets/1001/")!,
            id: try! DocketID(1001),
            caseName: "Doe v. United States",
            caseNameShort: "Doe",
            caseNameFull: "John Doe v. United States of America",
            docketNumber: "21-1234",
            courtID: try! CourtID("scotus"),
            court: URL(string: "https://www.courtlistener.com/api/rest/v4/courts/scotus/")!,
            dateFiled: "2021-03-15",
            dateTerminated: nil,
            dateLastFiling: "2021-11-01",
            dateCreated: Date(timeIntervalSince1970: 1_616_025_600),
            dateModified: Date(timeIntervalSince1970: 1_635_724_800),
            assignedToStr: "John Roberts",
            referredToStr: "",
            cause: "28 U.S.C. 1331",
            natureOfSuit: "Civil Rights",
            jurisdictionType: "Federal Question",
            blocked: false,
            slug: "doe-v-united-states",
            absoluteURL: "/docket/1001/doe-v-united-states/",
            clusters: [],
            tags: []
        )
    }
}
#endif
