/// The pure functional core. Given a message and the current model, returns a new model
/// and a list of commands (effects) to be executed by the imperative shell.
///
/// No side effects permitted here — no networking, no I/O, no mutation of external state.
public func update(
    message: CourtListenerMessage,
    model: CourtListenerModel
) -> (CourtListenerModel, [CourtListenerCommand]) {
    var m = model

    switch message {

    // MARK: - Court intents

    case .fetchCourt(let id):
        m.activeCommands.insert(.fetchCourt(id: id))
        m.lastError = nil
        return (m, [.fetchCourt(id: id)])

    case .listCourts(let cursor):
        let command = CourtListenerCommand.listCourts(cursor: cursor)
        m.activeCommands.insert(command)
        m.lastError = nil
        return (m, [command])

    // MARK: - Docket intents

    case .fetchDocket(let id):
        m.activeCommands.insert(.fetchDocket(id: id))
        m.lastError = nil
        return (m, [.fetchDocket(id: id)])

    case .searchDockets(let query):
        let command = CourtListenerCommand.searchDockets(query: query)
        m.activeCommands.insert(command)
        m.lastError = nil
        return (m, [command])

    // MARK: - Cluster / Opinion intents

    case .fetchCluster(let id):
        m.activeCommands.insert(.fetchCluster(id: id))
        m.lastError = nil
        return (m, [.fetchCluster(id: id)])

    case .listOpinions(let clusterID, let cursor):
        let command = CourtListenerCommand.listOpinions(clusterID: clusterID, cursor: cursor)
        m.activeCommands.insert(command)
        m.lastError = nil
        return (m, [command])

    // MARK: - Person intents

    case .fetchPerson(let id):
        m.activeCommands.insert(.fetchPerson(id: id))
        m.lastError = nil
        return (m, [.fetchPerson(id: id)])

    case .listPeople(let cursor):
        let command = CourtListenerCommand.listPeople(cursor: cursor)
        m.activeCommands.insert(command)
        m.lastError = nil
        return (m, [command])

    // MARK: - Party / Attorney intents

    case .fetchParties(let docketID):
        m.activeCommands.insert(.fetchParties(docketID: docketID))
        m.lastError = nil
        return (m, [.fetchParties(docketID: docketID)])

    case .fetchAttorneys(let docketID):
        m.activeCommands.insert(.fetchAttorneys(docketID: docketID))
        m.lastError = nil
        return (m, [.fetchAttorneys(docketID: docketID)])

    // MARK: - Response messages

    case .courtReceived(let court):
        m.courts[court.id] = court
        m.activeCommands.remove(.fetchCourt(id: court.id))
        return (m, [])

    case .courtsPageReceived(let page):
        for court in page.results {
            m.courts[court.id] = court
        }
        if case .total(let n) = page.count {
            m.courtsPagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: n
            )
        } else {
            m.courtsPagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: m.courtsPagination.totalCount
            )
        }
        m.activeCommands.remove(.listCourts(cursor: nil))
        return (m, [])

    case .docketReceived(let docket):
        m.dockets[docket.id] = docket
        m.activeCommands.remove(.fetchDocket(id: docket.id))
        return (m, [])

    case .docketsPageReceived(let page):
        for docket in page.results {
            m.dockets[docket.id] = docket
        }
        if case .total(let n) = page.count {
            m.docketsPagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: n
            )
        } else {
            m.docketsPagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: m.docketsPagination.totalCount
            )
        }
        return (m, [])

    case .clusterReceived(let cluster):
        m.clusters[cluster.id] = cluster
        m.activeCommands.remove(.fetchCluster(id: cluster.id))
        return (m, [])

    case .opinionsPageReceived(let page):
        for opinion in page.results {
            m.opinions[opinion.id] = opinion
        }
        return (m, [])

    case .personReceived(let person):
        m.people[person.id] = person
        m.activeCommands.remove(.fetchPerson(id: person.id))
        return (m, [])

    case .peoplePageReceived(let page):
        for person in page.results {
            m.people[person.id] = person
        }
        if case .total(let n) = page.count {
            m.peoplePagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: n
            )
        } else {
            m.peoplePagination = PaginationState(
                nextCursor: page.nextCursor,
                nextPage: page.nextPage,
                totalCount: m.peoplePagination.totalCount
            )
        }
        m.activeCommands.remove(.listPeople(cursor: nil))
        return (m, [])

    case .partiesReceived(let docketID, let parties):
        m.parties[docketID] = parties
        m.activeCommands.remove(.fetchParties(docketID: docketID))
        return (m, [])

    case .attorneysReceived(let docketID, let attorneys):
        m.attorneys[docketID] = attorneys
        m.activeCommands.remove(.fetchAttorneys(docketID: docketID))
        return (m, [])

    case .failed(let error):
        m.lastError = error
        m.activeCommands.removeAll()
        return (m, [])
    }
}
