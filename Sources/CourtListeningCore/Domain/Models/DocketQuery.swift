public struct DocketQuery: Sendable, Hashable, Codable {
    public var searchTerm: NonEmptyString?
    public var courtID: CourtID?
    public var caseName: NonEmptyString?
    public var docketNumber: NonEmptyString?
    public var cursor: Cursor?
    public var page: Int?

    public init(
        searchTerm: NonEmptyString? = nil,
        courtID: CourtID? = nil,
        caseName: NonEmptyString? = nil,
        docketNumber: NonEmptyString? = nil,
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
