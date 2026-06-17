public struct DocketQuery: Sendable, Hashable, Codable {
    public var searchTerm: String?
    public var courtID: CourtID?
    public var caseName: String?
    public var docketNumber: String?
    public var cursor: Cursor?
    public var page: Int?

    public init(
        searchTerm: String? = nil,
        courtID: CourtID? = nil,
        caseName: String? = nil,
        docketNumber: String? = nil,
        cursor: Cursor? = nil,
        page: Int? = nil
    ) {
        self.searchTerm = searchTerm
        self.courtID = courtID
        self.caseName = caseName
        self.docketNumber = docketNumber
        self.cursor = cursor
        self.page = page
    }
}
