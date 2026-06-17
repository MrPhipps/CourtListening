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

    public init(
        resourceURI: URL,
        id: CourtID,
        shortName: String,
        fullName: String,
        citationString: String,
        jurisdiction: Jurisdiction,
        inUse: Bool,
        hasOpinionScraper: Bool,
        hasOralArgumentScraper: Bool,
        position: Double,
        websiteURL: URL?,
        startDate: String?,
        endDate: String?,
        parentCourt: URL?,
        appealsTo: [URL],
        fjcCourtID: String,
        dateModified: Date
    ) {
        self.resourceURI = resourceURI
        self.id = id
        self.shortName = shortName
        self.fullName = fullName
        self.citationString = citationString
        self.jurisdiction = jurisdiction
        self.inUse = inUse
        self.hasOpinionScraper = hasOpinionScraper
        self.hasOralArgumentScraper = hasOralArgumentScraper
        self.position = position
        self.websiteURL = websiteURL
        self.startDate = startDate
        self.endDate = endDate
        self.parentCourt = parentCourt
        self.appealsTo = appealsTo
        self.fjcCourtID = fjcCourtID
        self.dateModified = dateModified
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        resourceURI = try c.decode(URL.self, forKey: .resourceURI)
        id = try c.decode(CourtID.self, forKey: .id)
        shortName = try c.decode(String.self, forKey: .shortName)
        fullName = try c.decode(String.self, forKey: .fullName)
        citationString = try c.decode(String.self, forKey: .citationString)
        jurisdiction = try c.decode(Jurisdiction.self, forKey: .jurisdiction)
        inUse = try c.decode(Bool.self, forKey: .inUse)
        hasOpinionScraper = try c.decode(Bool.self, forKey: .hasOpinionScraper)
        hasOralArgumentScraper = try c.decode(Bool.self, forKey: .hasOralArgumentScraper)
        position = try c.decode(Double.self, forKey: .position)
        // The API returns "" for courts with no website — treat blank/invalid as nil
        let urlString = try c.decodeIfPresent(String.self, forKey: .websiteURL)
        websiteURL = urlString.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try c.decodeIfPresent(String.self, forKey: .endDate)
        parentCourt = try c.decodeIfPresent(URL.self, forKey: .parentCourt)
        appealsTo = try c.decode([URL].self, forKey: .appealsTo)
        fjcCourtID = try c.decode(String.self, forKey: .fjcCourtID)
        dateModified = try c.decode(Date.self, forKey: .dateModified)
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
