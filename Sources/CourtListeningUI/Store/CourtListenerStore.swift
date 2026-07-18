import Foundation
import Observation
import CourtListeningCore
import CourtListening

/// The `@MainActor` presentation bridge over the `CourtListenerRunner` actor.
///
/// Holds the latest `CourtListenerModel` — a Sendable value-type **snapshot** — for SwiftUI
/// to observe. All intents go through `send`, which hops to the actor, lets the pure loop run
/// to quiescence, then reads the new snapshot back on the main actor. The domain model never
/// becomes an `@Observable` class; only this thin wrapper is observable.
@MainActor
@Observable
public final class CourtListenerStore {
    public private(set) var model: CourtListenerModel

    @ObservationIgnored private let runner: CourtListenerRunner

    public init(token: APIToken, transport: (any HTTPTransport)? = nil) {
        self.model = .initial
        self.runner = CourtListenerRunner(token: token, transport: transport)
    }

    /// Dispatches an intent and refreshes the observable snapshot when the loop settles.
    public func send(_ message: CourtListenerMessage) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runner.handle(message: message)
            self.model = await self.runner.model
        }
    }

    // MARK: - Convenience intents (typed at the call site, no primitives leaking into views)

    public func loadCourts(page: Int? = nil) { send(.listCourts(page: page)) }
    public func loadNextCourtsPage() {
        if let next = model.courtsPagination.nextPage { send(.listCourts(page: next)) }
    }
    public func searchDockets(_ query: DocketQuery) { send(.searchDockets(query)) }
    public func loadCluster(_ id: ClusterID) { send(.fetchCluster(id)) }
    public func loadOpinions(clusterID: ClusterID, cursor: Cursor? = nil) {
        send(.listOpinions(clusterID: clusterID, cursor: cursor))
    }
    public func loadParties(docketID: DocketID) { send(.fetchParties(docketID: docketID)) }
    public func loadAttorneys(docketID: DocketID) { send(.fetchAttorneys(docketID: docketID)) }
    public func loadOralArguments(docketID: DocketID) { send(.fetchOralArguments(docketID: docketID)) }
}

#if DEBUG
extension CourtListenerStore {
    /// Builds a store with a preloaded snapshot for SwiftUI previews (no network).
    public static func preview(_ model: CourtListenerModel = .initial) -> CourtListenerStore {
        let store = CourtListenerStore(
            token: try! APIToken("preview_token_1234"),
            transport: CourtListenerTransport.stubbed(responses: [:])
        )
        store.model = model
        return store
    }
}
#endif
