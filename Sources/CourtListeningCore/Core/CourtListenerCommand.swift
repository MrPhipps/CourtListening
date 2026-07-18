public enum CourtListenerCommand: Sendable, Hashable, Codable {
    case fetchCourt(id: CourtID)
    case listCourts(page: Int?)
    case fetchDocket(id: DocketID)
    case searchDockets(query: DocketQuery)
    case fetchCluster(id: ClusterID)
    case listOpinions(clusterID: ClusterID, cursor: Cursor?)
    case fetchPerson(id: PersonID)
    case listPeople(cursor: Cursor?)
    case fetchParties(docketID: DocketID)
    case fetchAttorneys(docketID: DocketID)
}
