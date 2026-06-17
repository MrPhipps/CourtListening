import Foundation

public struct Court: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: CourtID
    public let shortName: String
    public let fullName: String
    public let citationString: String
    public let jurisdiction: Jurisdiction
    public let inUse: Bool
    public let hasOpinionScraper: Bool
    public let hasOralArgumentScraper: Bool
    public let position: Double
    public let websiteURL: URL?
    public let startDate: String?
    public let endDate: String?
    public let parentCourt: URL?
    public let appealsTo: [URL]
    public let fjcCourtID: String
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case shortName = "short_name"
        case fullName = "full_name"
        case citationString = "citation_string"
        case jurisdiction
        case inUse = "in_use"
        case hasOpinionScraper = "has_opinion_scraper"
        case hasOralArgumentScraper = "has_oral_argument_scraper"
        case position
        case websiteURL = "url"
        case startDate = "start_date"
        case endDate = "end_date"
        case parentCourt = "parent_court"
        case appealsTo = "appeals_to"
        case fjcCourtID = "fjc_court_id"
        case dateModified = "date_modified"
    }
}

#if DEBUG
extension Court {
    public enum TestData {
        public static let supremeCourt = Court(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/courts/scotus/")!,
            id: try! CourtID("scotus"),
            shortName: "Supreme Court",
            fullName: "Supreme Court of the United States",
            citationString: "SCOTUS",
            jurisdiction: .federal,
            inUse: true,
            hasOpinionScraper: true,
            hasOralArgumentScraper: true,
            position: 1.0,
            websiteURL: URL(string: "http://supremecourt.gov/"),
            startDate: "1789-09-24",
            endDate: nil,
            parentCourt: nil,
            appealsTo: [],
            fjcCourtID: "",
            dateModified: Date(timeIntervalSince1970: 1_414_720_755)
        )

        public static let firstCircuit = Court(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/courts/ca1/")!,
            id: try! CourtID("ca1"),
            shortName: "First Circuit",
            fullName: "Court of Appeals for the First Circuit",
            citationString: "1st Cir.",
            jurisdiction: .federal,
            inUse: true,
            hasOpinionScraper: true,
            hasOralArgumentScraper: true,
            position: 101.0,
            websiteURL: URL(string: "http://www.ca1.uscourts.gov/"),
            startDate: "1891-03-03",
            endDate: nil,
            parentCourt: nil,
            appealsTo: [],
            fjcCourtID: "1",
            dateModified: Date(timeIntervalSince1970: 1_677_074_893)
        )
    }
}
#endif
