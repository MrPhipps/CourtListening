public struct CourtListenerModel: Sendable {
    public var courts: [CourtID: Court]
    public var dockets: [DocketID: Docket]
    public var clusters: [ClusterID: OpinionCluster]
    public var opinions: [OpinionID: Opinion]
    public var people: [PersonID: Person]
    public var parties: [DocketID: [Party]]
    public var attorneys: [DocketID: [Attorney]]
    public var oralArguments: [DocketID: [Audio]]
    public var courtsPagination: PaginationState
    public var docketsPagination: PaginationState
    public var opinionsPagination: PaginationState
    public var peoplePagination: PaginationState
    public var activeCommands: Set<CourtListenerCommand>
    public var apiUsage: APIUsage
    public var lastError: CourtListenerError?

    public static let initial = CourtListenerModel(
        courts: [:],
        dockets: [:],
        clusters: [:],
        opinions: [:],
        people: [:],
        parties: [:],
        attorneys: [:],
        oralArguments: [:],
        courtsPagination: .initial,
        docketsPagination: .initial,
        opinionsPagination: .initial,
        peoplePagination: .initial,
        activeCommands: [],
        apiUsage: .initial,
        lastError: nil
    )
}

#if DEBUG
extension CourtListenerModel {
    public enum TestVariants {
        public static let empty = CourtListenerModel.initial

        public static let loadingCourts: CourtListenerModel = {
            var m = CourtListenerModel.initial
            m.activeCommands = [.listCourts(page: nil)]
            return m
        }()

        public static let withSCOTUS: CourtListenerModel = {
            var m = CourtListenerModel.initial
            m.courts[Court.TestData.supremeCourt.id] = Court.TestData.supremeCourt
            return m
        }()

        public static let withError: CourtListenerModel = {
            var m = CourtListenerModel.initial
            m.lastError = .unauthorized
            return m
        }()
    }
}
#endif
