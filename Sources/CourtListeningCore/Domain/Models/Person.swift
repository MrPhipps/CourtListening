import Foundation

public struct Person: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: PersonID
    public let slug: String
    public let nameFirst: String
    public let nameMiddle: String
    public let nameLast: String
    public let nameSuffix: String
    public let gender: Gender
    public let dateOfBirth: String?
    public let dateOfBirthGranularity: DateGranularity
    public let dateOfDeath: String?
    public let dateOfDeathGranularity: DateGranularity
    public let dobCity: String
    public let dobState: String
    public let dobCountry: String
    public let hasPhoto: Bool
    public let positions: [URL]
    public let educations: [URL]
    public let race: [String]
    public let fjcID: String?
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case slug
        case nameFirst = "name_first"
        case nameMiddle = "name_middle"
        case nameLast = "name_last"
        case nameSuffix = "name_suffix"
        case gender
        case dateOfBirth = "date_dob"
        case dateOfBirthGranularity = "date_granularity_dob"
        case dateOfDeath = "date_dod"
        case dateOfDeathGranularity = "date_granularity_dod"
        case dobCity = "dob_city"
        case dobState = "dob_state"
        case dobCountry = "dob_country"
        case hasPhoto = "has_photo"
        case positions
        case educations
        case race
        case fjcID = "fjc_id"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }

    public var fullName: String {
        [nameFirst, nameMiddle, nameLast, nameSuffix]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

#if DEBUG
extension Person {
    public enum TestData {
        public static let angelKelley = Person(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/people/16242/")!,
            id: try! PersonID(16242),
            slug: "angel-kelley",
            nameFirst: "Angel",
            nameMiddle: "",
            nameLast: "Kelley",
            nameSuffix: "",
            gender: .female,
            dateOfBirth: "1967-01-01",
            dateOfBirthGranularity: .year,
            dateOfDeath: nil,
            dateOfDeathGranularity: .unknown,
            dobCity: "New Rochelle",
            dobState: "NY",
            dobCountry: "United States",
            hasPhoto: false,
            positions: [URL(string: "https://www.courtlistener.com/api/rest/v4/positions/52645/")!],
            educations: [],
            race: [],
            fjcID: nil,
            dateCreated: Date(timeIntervalSince1970: 1_747_254_495),
            dateModified: Date(timeIntervalSince1970: 1_747_254_495)
        )
    }
}
#endif
