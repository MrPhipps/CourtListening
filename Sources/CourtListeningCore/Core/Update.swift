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

    // MARK: - Infrastructure

    case .usageRecorded(let at):
        m.apiUsage = m.apiUsage.recording(at: at)
        return (m, [])

    // MARK: - Court intents

    case .fetchCourt(let id):
        m.activeCommands.insert(.fetchCourt(id: id))
        m.lastError = nil
        return (m, [.fetchCourt(id: id)])

    case .listCourts(let page):
        let command = CourtListenerCommand.listCourts(page: page)
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

    case .fetchOralArguments(let docketID):
        m.activeCommands.insert(.fetchOralArguments(docketID: docketID))
        m.lastError = nil
        return (m, [.fetchOralArguments(docketID: docketID)])

    // MARK: - Response messages

    case .courtReceived(let court):
        m.courts[court.id] = court
        m.activeCommands.remove(.fetchCourt(id: court.id))
        return (m, [])

    case .courtsPageReceived(let page):
        for court in page.results { m.courts[court.id] = court }
        m.courtsPagination = PaginationState(
            nextCursor: page.nextCursor,
            nextPage: page.nextPage,
            totalCount: page.count.total ?? m.courtsPagination.totalCount
        )
        m.activeCommands = m.activeCommands.removingAll { if case .listCourts = $0 { return true }; return false }
        return (m, [])

    case .docketReceived(let docket):
        m.dockets[docket.id] = docket
        m.activeCommands.remove(.fetchDocket(id: docket.id))
        return (m, [])

    case .docketsPageReceived(let page):
        for docket in page.results { m.dockets[docket.id] = docket }
        m.docketsPagination = PaginationState(
            nextCursor: page.nextCursor,
            nextPage: page.nextPage,
            totalCount: page.count.total ?? m.docketsPagination.totalCount
        )
        m.activeCommands = m.activeCommands.removingAll { if case .searchDockets = $0 { return true }; return false }
        return (m, [])

    case .clusterReceived(let cluster):
        m.clusters[cluster.id] = cluster
        m.activeCommands.remove(.fetchCluster(id: cluster.id))
        return (m, [])

    case .opinionsPageReceived(let page):
        for opinion in page.results { m.opinions[opinion.id] = opinion }
        m.opinionsPagination = PaginationState(
            nextCursor: page.nextCursor,
            nextPage: page.nextPage,
            totalCount: page.count.total ?? m.opinionsPagination.totalCount
        )
        m.activeCommands = m.activeCommands.removingAll { if case .listOpinions = $0 { return true }; return false }
        return (m, [])

    case .personReceived(let person):
        m.people[person.id] = person
        m.activeCommands.remove(.fetchPerson(id: person.id))
        return (m, [])

    case .peoplePageReceived(let page):
        for person in page.results { m.people[person.id] = person }
        m.peoplePagination = PaginationState(
            nextCursor: page.nextCursor,
            nextPage: page.nextPage,
            totalCount: page.count.total ?? m.peoplePagination.totalCount
        )
        m.activeCommands = m.activeCommands.removingAll { if case .listPeople = $0 { return true }; return false }
        return (m, [])

    case .partiesReceived(let docketID, let parties):
        m.parties[docketID] = parties
        m.activeCommands.remove(.fetchParties(docketID: docketID))
        return (m, [])

    case .attorneysReceived(let docketID, let attorneys):
        m.attorneys[docketID] = attorneys
        m.activeCommands.remove(.fetchAttorneys(docketID: docketID))
        return (m, [])

    case .oralArgumentsReceived(let docketID, let recordings):
        m.oralArguments[docketID] = recordings
        m.activeCommands.remove(.fetchOralArguments(docketID: docketID))
        return (m, [])

    // MARK: - Failure

    case .commandFailed(let error, let command):
        m.lastError = error
        m.activeCommands.remove(command)
        return (m, [])
    }
}

// MARK: - Helpers

private extension Set {
    func removingAll(where predicate: (Element) -> Bool) -> Set {
        filter { !predicate($0) }
    }
}

private extension ResponseCount {
    var total: Int? {
        if case .total(let n) = self { return n }
        return nil
    }
}
