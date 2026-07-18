import Foundation
import CourtListeningCore

enum Endpoints {
    static let base = URL(string: "https://www.courtlistener.com/api/rest/v4/")!

    static func court(_ id: CourtID) -> URL {
        base.appending(path: "courts/\(id.rawValue)/")
    }

    // /courts/ uses page-number pagination (?page=N) with an integer `count`,
    // unlike the cursor-based list endpoints. Verified live against the v4 API.
    static func courts(page: Int? = nil) -> URL {
        var components = URLComponents(url: base.appending(path: "courts/"), resolvingAgainstBaseURL: false)!
        if let page {
            components.queryItems = [URLQueryItem(name: "page", value: "\(page)")]
        }
        return components.url!
    }

    static func docket(_ id: DocketID) -> URL {
        base.appending(path: "dockets/\(id.rawValue)/")
    }

    static func dockets(query: DocketQuery) -> URL {
        var items: [URLQueryItem] = []
        if let term = query.searchTerm { items.append(URLQueryItem(name: "search", value: term.rawValue)) }
        if let court = query.courtID { items.append(URLQueryItem(name: "court_id", value: court.rawValue)) }
        if let name = query.caseName { items.append(URLQueryItem(name: "case_name", value: name.rawValue)) }
        if let number = query.docketNumber { items.append(URLQueryItem(name: "docket_number", value: number.rawValue)) }
        if let cursor = query.cursor { items.append(URLQueryItem(name: "cursor", value: cursor.rawValue)) }
        if let page = query.page { items.append(URLQueryItem(name: "page", value: "\(page)")) }
        var components = URLComponents(url: base.appending(path: "dockets/"), resolvingAgainstBaseURL: false)!
        if !items.isEmpty { components.queryItems = items }
        return components.url!
    }

    static func cluster(_ id: ClusterID) -> URL {
        base.appending(path: "clusters/\(id.rawValue)/")
    }

    static func opinions(clusterID: ClusterID, cursor: Cursor? = nil) -> URL {
        var components = URLComponents(url: base.appending(path: "opinions/"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "cluster", value: "\(clusterID.rawValue)")]
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor.rawValue)) }
        components.queryItems = items
        return components.url!
    }

    static func person(_ id: PersonID) -> URL {
        base.appending(path: "people/\(id.rawValue)/")
    }

    static func people(cursor: Cursor? = nil) -> URL {
        var components = URLComponents(url: base.appending(path: "people/"), resolvingAgainstBaseURL: false)!
        if let cursor {
            components.queryItems = [URLQueryItem(name: "cursor", value: cursor.rawValue)]
        }
        return components.url!
    }

    static func parties(docketID: DocketID) -> URL {
        var components = URLComponents(url: base.appending(path: "parties/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "docket", value: "\(docketID.rawValue)")]
        return components.url!
    }

    static func attorneys(docketID: DocketID) -> URL {
        var components = URLComponents(url: base.appending(path: "attorneys/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "docket", value: "\(docketID.rawValue)")]
        return components.url!
    }

    static func oralArguments(docketID: DocketID) -> URL {
        var components = URLComponents(url: base.appending(path: "audio/"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "docket", value: "\(docketID.rawValue)")]
        return components.url!
    }
}
