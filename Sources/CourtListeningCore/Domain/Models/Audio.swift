import Foundation

/// An oral-argument audio recording from CourtListener's `/audio/` endpoint.
///
/// Audio is linked to a docket (top-level `docket` URL — verified live) and carries the
/// recording's playable source (`downloadURL`) plus metadata. Fetched per docket via
/// `?docket=<id>` (cursor-based pagination).
public struct Audio: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: AudioID
    public let docket: URL
    public let caseName: String
    public let caseNameShort: String
    public let caseNameFull: String
    public let judges: String
    /// Recording length in whole seconds.
    public let duration: Int
    /// Direct source of the mp3 (often a court CDN). Blank/invalid in the API → nil.
    public let downloadURL: URL?
    /// CourtListener-relative mp3 path (e.g. "mp3/2026/07/16/in_re_catron_cl.mp3").
    public let localPathMP3: String
    public let sha1: String
    public let source: String
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case docket
        case caseName = "case_name"
        case caseNameShort = "case_name_short"
        case caseNameFull = "case_name_full"
        case judges
        case duration
        case downloadURL = "download_url"
        case localPathMP3 = "local_path_mp3"
        case sha1
        case source
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }

    public init(
        resourceURI: URL,
        id: AudioID,
        docket: URL,
        caseName: String,
        caseNameShort: String,
        caseNameFull: String,
        judges: String,
        duration: Int,
        downloadURL: URL?,
        localPathMP3: String,
        sha1: String,
        source: String,
        dateCreated: Date,
        dateModified: Date
    ) {
        self.resourceURI = resourceURI
        self.id = id
        self.docket = docket
        self.caseName = caseName
        self.caseNameShort = caseNameShort
        self.caseNameFull = caseNameFull
        self.judges = judges
        self.duration = duration
        self.downloadURL = downloadURL
        self.localPathMP3 = localPathMP3
        self.sha1 = sha1
        self.source = source
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        resourceURI = try c.decode(URL.self, forKey: .resourceURI)
        id = try c.decode(AudioID.self, forKey: .id)
        docket = try c.decode(URL.self, forKey: .docket)
        caseName = try c.decode(String.self, forKey: .caseName)
        caseNameShort = try c.decodeIfPresent(String.self, forKey: .caseNameShort) ?? ""
        caseNameFull = try c.decodeIfPresent(String.self, forKey: .caseNameFull) ?? ""
        judges = try c.decodeIfPresent(String.self, forKey: .judges) ?? ""
        duration = try c.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        // The API returns "" for recordings with no direct download — treat blank/invalid as nil.
        let urlString = try c.decodeIfPresent(String.self, forKey: .downloadURL)
        downloadURL = urlString.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        localPathMP3 = try c.decodeIfPresent(String.self, forKey: .localPathMP3) ?? ""
        sha1 = try c.decodeIfPresent(String.self, forKey: .sha1) ?? ""
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? ""
        dateCreated = try c.decode(Date.self, forKey: .dateCreated)
        dateModified = try c.decode(Date.self, forKey: .dateModified)
    }
}

#if DEBUG
extension Audio {
    public enum TestData {
        public static let inReCatron = Audio(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/audio/105800/")!,
            id: try! AudioID(105800),
            docket: URL(string: "https://www.courtlistener.com/api/rest/v4/dockets/73632039/")!,
            caseName: "In re Catron",
            caseNameShort: "Catron",
            caseNameFull: "In re Catron",
            judges: "",
            duration: 569,
            downloadURL: URL(string: "https://cdn.ca9.uscourts.gov/datastore/media/2026/07/16/25-1137.mp3"),
            localPathMP3: "mp3/2026/07/16/in_re_catron_cl.mp3",
            sha1: "9e666202142717d5a4f6ed06739f0e701d66edae",
            source: "C",
            dateCreated: Date(timeIntervalSince1970: 1_752_712_239),
            dateModified: Date(timeIntervalSince1970: 1_752_712_376)
        )
    }
}
#endif
