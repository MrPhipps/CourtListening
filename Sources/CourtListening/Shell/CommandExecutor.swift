import Foundation
import CourtListeningCore

extension CourtListenerRunner {
    func execute(_ command: CourtListenerCommand) async -> CourtListenerMessage? {
        do {
            return try await executeOrThrow(command)
        } catch let error as CourtListenerError {
            return .failed(error)
        } catch let error as NetworkError {
            return .failed(mapNetworkError(error))
        } catch {
            return .failed(.unknown(error.localizedDescription))
        }
    }

    private func executeOrThrow(_ command: CourtListenerCommand) async throws -> CourtListenerMessage? {
        switch command {

        case .fetchCourt(let id):
            let url = Endpoints.court(id)
            let data = try await fetch(url)
            let court = try ResponseDecoder.shared.decode(Court.self, from: data)
            return .courtReceived(court)

        case .listCourts(let cursor):
            let url = Endpoints.courts(cursor: cursor)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Court>.self, from: data)
            return .courtsPageReceived(page)

        case .fetchDocket(let id):
            let url = Endpoints.docket(id)
            let data = try await fetch(url)
            let docket = try ResponseDecoder.shared.decode(Docket.self, from: data)
            return .docketReceived(docket)

        case .searchDockets(let query):
            let url = Endpoints.dockets(query: query)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Docket>.self, from: data)
            return .docketsPageReceived(page)

        case .fetchCluster(let id):
            let url = Endpoints.cluster(id)
            let data = try await fetch(url)
            let cluster = try ResponseDecoder.shared.decode(OpinionCluster.self, from: data)
            return .clusterReceived(cluster)

        case .listOpinions(let clusterID, let cursor):
            let url = Endpoints.opinions(clusterID: clusterID, cursor: cursor)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Opinion>.self, from: data)
            return .opinionsPageReceived(page)

        case .fetchPerson(let id):
            let url = Endpoints.person(id)
            let data = try await fetch(url)
            let person = try ResponseDecoder.shared.decode(Person.self, from: data)
            return .personReceived(person)

        case .listPeople(let cursor):
            let url = Endpoints.people(cursor: cursor)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Person>.self, from: data)
            return .peoplePageReceived(page)

        case .fetchParties(let docketID):
            let url = Endpoints.parties(docketID: docketID)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Party>.self, from: data)
            return .partiesReceived(docketID: docketID, page.results)

        case .fetchAttorneys(let docketID):
            let url = Endpoints.attorneys(docketID: docketID)
            let data = try await fetch(url)
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Attorney>.self, from: data)
            return .attorneysReceived(docketID: docketID, page.results)
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token.authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        let (data, response) = try await transport.data(for: request)
        return try validated(data: data, response: response)
    }

    private func validated(data: Data, response: HTTPURLResponse) throws -> Data {
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
            throw CourtListenerError.unauthorized
        case 403:
            throw CourtListenerError.forbidden
        case 404:
            throw CourtListenerError.notFound(response.url?.path ?? "unknown")
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw CourtListenerError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            throw CourtListenerError.serverError(statusCode: response.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(response.statusCode)
        }
    }
}

private func mapNetworkError(_ error: NetworkError) -> CourtListenerError {
    switch error {
    case .requestFailed(let urlError) where urlError.code == .notConnectedToInternet:
        return .networkUnavailable
    case .requestFailed(let urlError) where urlError.code == .networkConnectionLost:
        return .networkUnavailable
    default:
        return .unknown(error.localizedDescription)
    }
}
