import Foundation

public struct OpinionCluster: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: ClusterID
    public let caseName: String
    public let caseNameShort: String
    public let caseNameFull: String
    public let docket: URL
    public let dateFiled: String?
    public let dateFiledIsApproximate: Bool
    public let judges: String
    public let natureOfSuit: String
    public let precedentialStatus: PrecedentialStatus
    public let citationCount: Int
    public let blocked: Bool
    public let attorneys: String
    public let dateCreated: Date
    public let dateModified: Date
    public let subOpinions: [URL]

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case caseName = "case_name"
        case caseNameShort = "case_name_short"
        case caseNameFull = "case_name_full"
        case docket
        case dateFiled = "date_filed"
        case dateFiledIsApproximate = "date_filed_is_approximate"
        case judges
        case natureOfSuit = "nature_of_suit"
        case precedentialStatus = "precedential_status"
        case citationCount = "citation_count"
        case blocked
        case attorneys
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case subOpinions = "sub_opinions"
    }
}

public enum PrecedentialStatus: String, Codable, Sendable, Hashable, CaseIterable {
    case published = "Published"
    case unpublished = "Unpublished"
    case errata = "Errata"
    case separateOpinion = "Separate Opinion"
    case inChambers = "In-chambers"
    case lawReviewAndJournals = "Relating-to orders"
    case precedential = "Precedential"
    case nonPrecedential = "Non-Precedential"
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PrecedentialStatus(rawValue: raw) ?? .unknown
    }
}

#if DEBUG
extension OpinionCluster {
    public enum TestData {
        public static let sampleCluster = OpinionCluster(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/clusters/2001/")!,
            id: try! ClusterID(2001),
            caseName: "Doe v. United States",
            caseNameShort: "Doe",
            caseNameFull: "John Doe v. United States of America",
            docket: URL(string: "https://www.courtlistener.com/api/rest/v4/dockets/1001/")!,
            dateFiled: "2022-06-15",
            dateFiledIsApproximate: false,
            judges: "Roberts",
            natureOfSuit: "",
            precedentialStatus: .published,
            citationCount: 12,
            blocked: false,
            attorneys: "Jane Smith for petitioner",
            dateCreated: Date(timeIntervalSince1970: 1_655_251_200),
            dateModified: Date(timeIntervalSince1970: 1_655_251_200),
            subOpinions: [URL(string: "https://www.courtlistener.com/api/rest/v4/opinions/3001/")!]
        )
    }
}
#endif
