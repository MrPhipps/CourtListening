import Foundation
import CourtListeningCore

extension CourtListenerRunner {

    /// Executes a command and returns all resulting messages, including a `usageRecorded`
    /// message for every request that reached the server (including 4xx/5xx responses).
    /// Pure network failures (no server contact) do not produce a `usageRecorded` message.
    func execute(_ command: CourtListenerCommand) async -> [CourtListenerMessage] {
        let requestedAt = Date()
        do {
            let result = try await executeOrThrow(command)
            var messages: [CourtListenerMessage] = [.usageRecorded(at: requestedAt)]
            if let result { messages.append(result) }
            return messages
        } catch let error as CourtListenerError {
            // HTTP reached the server — record usage regardless of status code
            return [.usageRecorded(at: requestedAt), .commandFailed(error, command)]
        } catch let error as NetworkError {
            // Network-level failure — request never reached the server
            return [.commandFailed(mapNetworkError(error), command)]
        } catch {
            return [.commandFailed(.unknown(error.localizedDescription), command)]
        }
    }

    private func executeOrThrow(_ command: CourtListenerCommand) async throws -> CourtListenerMessage? {
        switch command {

        case .fetchCourt(let id):
            let data = try await fetch(Endpoints.court(id))
            return .courtReceived(try ResponseDecoder.shared.decode(Court.self, from: data))

        case .listCourts(let cursor):
            let data = try await fetch(Endpoints.courts(cursor: cursor))
            return .courtsPageReceived(try ResponseDecoder.shared.decode(PaginatedResponse<Court>.self, from: data))

        case .fetchDocket(let id):
            let data = try await fetch(Endpoints.docket(id))
            return .docketReceived(try ResponseDecoder.shared.decode(Docket.self, from: data))

        case .searchDockets(let query):
            let data = try await fetch(Endpoints.dockets(query: query))
            return .docketsPageReceived(try ResponseDecoder.shared.decode(PaginatedResponse<Docket>.self, from: data))

        case .fetchCluster(let id):
            let data = try await fetch(Endpoints.cluster(id))
            return .clusterReceived(try ResponseDecoder.shared.decode(OpinionCluster.self, from: data))

        case .listOpinions(let clusterID, let cursor):
            let data = try await fetch(Endpoints.opinions(clusterID: clusterID, cursor: cursor))
            return .opinionsPageReceived(try ResponseDecoder.shared.decode(PaginatedResponse<Opinion>.self, from: data))

        case .fetchPerson(let id):
            let data = try await fetch(Endpoints.person(id))
            return .personReceived(try ResponseDecoder.shared.decode(Person.self, from: data))

        case .listPeople(let cursor):
            let data = try await fetch(Endpoints.people(cursor: cursor))
            return .peoplePageReceived(try ResponseDecoder.shared.decode(PaginatedResponse<Person>.self, from: data))

        case .fetchParties(let docketID):
            let data = try await fetch(Endpoints.parties(docketID: docketID))
            let page = try ResponseDecoder.shared.decode(PaginatedResponse<Party>.self, from: data)
            return .partiesReceived(docketID: docketID, page.results)

        case .fetchAttorneys(let docketID):
            let data = try await fetch(Endpoints.attorneys(docketID: docketID))
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
            throw CourtListenerError.notFound(response.url)
        case 429:
            // CL returns {"wait_until": "<ISO-8601 datetime>"} in the 429 body
            let until = (try? ResponseDecoder.shared.decode(RateLimitBody.self, from: data))?.waitUntil
            throw CourtListenerError.rateLimited(until: until)
        case 500...599:
            throw CourtListenerError.serverError(statusCode: response.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(response.statusCode)
        }
    }
}

private struct RateLimitBody: Codable {
    let waitUntil: Date
    enum CodingKeys: String, CodingKey { case waitUntil = "wait_until" }
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
