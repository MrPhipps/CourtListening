public struct CourtListenerModel: Sendable {
    public var courts: [CourtID: Court]
    public var dockets: [DocketID: Docket]
    public var clusters: [ClusterID: OpinionCluster]
    public var opinions: [OpinionID: Opinion]
    public var people: [PersonID: Person]
    public var parties: [DocketID: [Party]]
    public var attorneys: [DocketID: [Attorney]]
    public var courtsPagination: PaginationState
    public var docketsPagination: PaginationState
    public var peoplePagination: PaginationState
    public var activeCommands: Set<CourtListenerCommand>
    public var lastError: CourtListenerError?

    public static let initial = CourtListenerModel(
        courts: [:],
        dockets: [:],
        clusters: [:],
        opinions: [:],
        people: [:],
        parties: [:],
        attorneys: [:],
        courtsPagination: .initial,
        docketsPagination: .initial,
        peoplePagination: .initial,
        activeCommands: [],
        lastError: nil
    )
}

#if DEBUG
extension CourtListenerModel {
    public enum TestVariants {
        public static let empty = CourtListenerModel.initial

        public static let loadingCourts = CourtListenerModel(
            courts: [:],
            dockets: [:],
            clusters: [:],
            opinions: [:],
            people: [:],
            parties: [:],
            attorneys: [:],
            courtsPagination: .initial,
            docketsPagination: .initial,
            peoplePagination: .initial,
            activeCommands: [.listCourts(cursor: nil)],
            lastError: nil
        )

        public static let withSCOTUS: CourtListenerModel = {
            let court = Court.TestData.supremeCourt
            var m = CourtListenerModel.initial
            m.courts[court.id] = court
            return m
        }()

        public static let withError = CourtListenerModel(
            courts: [:],
            dockets: [:],
            clusters: [:],
            opinions: [:],
            people: [:],
            parties: [:],
            attorneys: [:],
            courtsPagination: .initial,
            docketsPagination: .initial,
            peoplePagination: .initial,
            activeCommands: [],
            lastError: .unauthorized
        )
    }
}
#endif
