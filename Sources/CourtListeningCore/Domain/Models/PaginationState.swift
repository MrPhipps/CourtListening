public struct PaginationState: Sendable, Hashable {
    public var nextCursor: String?
    public var nextPage: Int?
    public var totalCount: Int?

    public static let initial = PaginationState(nextCursor: nil, nextPage: nil, totalCount: nil)

    public var hasMore: Bool {
        nextCursor != nil || nextPage != nil
    }
}
