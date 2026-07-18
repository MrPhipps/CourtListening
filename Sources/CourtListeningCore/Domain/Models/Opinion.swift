import Foundation

public struct Opinion: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: OpinionID
    public let cluster: URL
    public let author: URL?
    public let authorStr: String
    public let perCuriam: Bool
    public let type: OpinionType
    public let sha1: String
    public let pageCount: Int?
    public let downloadURL: URL?
    public let extractedByOCR: Bool
    public let plainText: String
    public let html: String
    public let htmlLawbox: String
    public let htmlColumbia: String
    public let htmlWithCitations: String
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case cluster
        case author
        case authorStr = "author_str"
        case perCuriam = "per_curiam"
        case type
        case sha1
        case pageCount = "page_count"
        case downloadURL = "download_url"
        case extractedByOCR = "extracted_by_ocr"
        case plainText = "plain_text"
        case html
        case htmlLawbox = "html_lawbox"
        case htmlColumbia = "html_columbia"
        case htmlWithCitations = "html_with_citations"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }

    public var hasText: Bool { !plainText.isEmpty || !html.isEmpty }
}

#if DEBUG
extension Opinion {
    public enum TestData {
        public static let sampleOpinion = Opinion(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/opinions/3001/")!,
            id: try! OpinionID(3001),
            cluster: URL(string: "https://www.courtlistener.com/api/rest/v4/clusters/2001/")!,
            author: nil,
            authorStr: "Roberts",
            perCuriam: false,
            type: .combined,
            sha1: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
            pageCount: 24,
            downloadURL: nil,
            extractedByOCR: false,
            plainText: "The judgment of the Court of Appeals is affirmed.",
            html: "<p>The judgment of the Court of Appeals is affirmed.</p>",
            htmlLawbox: "",
            htmlColumbia: "",
            htmlWithCitations: "",
            dateCreated: Date(timeIntervalSince1970: 1_655_251_200),
            dateModified: Date(timeIntervalSince1970: 1_655_251_200)
        )
    }
}
#endif
