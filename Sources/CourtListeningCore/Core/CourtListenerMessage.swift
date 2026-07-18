import Foundation

public enum CourtListenerMessage: Sendable {
    // MARK: - Infrastructure messages (emitted by the shell, not by callers)

    /// Records that one HTTP request completed at the given time.
    /// Emitted by the shell after every request that reached the server (including 4xx/5xx).
    case usageRecorded(at: Date)

    // MARK: - Intent messages (sent by callers)

    case fetchCourt(CourtID)
    // /courts/ is page-based (?page=N), not cursor-based — see Endpoints.courts(page:).
    case listCourts(page: Int?)
    case fetchDocket(DocketID)
    case searchDockets(DocketQuery)
    case fetchCluster(ClusterID)
    case listOpinions(clusterID: ClusterID, cursor: Cursor?)
    case fetchPerson(PersonID)
    case listPeople(cursor: Cursor?)
    case fetchParties(docketID: DocketID)
    case fetchAttorneys(docketID: DocketID)

    // MARK: - Response messages (fed back from the shell after executing commands)

    case courtReceived(Court)
    case courtsPageReceived(PaginatedResponse<Court>)
    case docketReceived(Docket)
    case docketsPageReceived(PaginatedResponse<Docket>)
    case clusterReceived(OpinionCluster)
    case opinionsPageReceived(PaginatedResponse<Opinion>)
    case personReceived(Person)
    case peoplePageReceived(PaginatedResponse<Person>)
    case partiesReceived(docketID: DocketID, [Party])
    case attorneysReceived(docketID: DocketID, [Attorney])

    // MARK: - Failure messages

    /// A specific command failed. Only that command's entry in activeCommands is cleared.
    /// Prefer this over a generic failure whenever the failing command is known (always in the shell).
    case commandFailed(CourtListenerError, CourtListenerCommand)
}
