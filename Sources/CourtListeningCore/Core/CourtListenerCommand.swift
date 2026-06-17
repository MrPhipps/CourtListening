public enum CourtListenerCommand: Sendable, Hashable, Codable {
    case fetchCourt(id: CourtID)
    case listCourts(cursor: String?)
    case fetchDocket(id: DocketID)
    case searchDockets(query: DocketQuery)
    case fetchCluster(id: ClusterID)
    case listOpinions(clusterID: ClusterID, cursor: String?)
    case fetchPerson(id: PersonID)
    case listPeople(cursor: String?)
    case fetchParties(docketID: DocketID)
    case fetchAttorneys(docketID: DocketID)
}
