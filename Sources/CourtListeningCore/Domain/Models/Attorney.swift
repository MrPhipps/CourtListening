import Foundation

public struct Attorney: Sendable, Codable, Hashable {
    public let resourceURI: URL
    public let id: AttorneyID
    public let name: String
    public let contactRaw: String
    public let phone: PhoneNumber?
    public let fax: PhoneNumber?
    public let email: EmailAddress?
    public let dateCreated: Date
    public let dateModified: Date

    enum CodingKeys: String, CodingKey {
        case resourceURI = "resource_uri"
        case id
        case name
        case contactRaw = "contact_raw"
        case phone
        case fax
        case email
        case dateCreated = "date_created"
        case dateModified = "date_modified"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        resourceURI = try c.decode(URL.self, forKey: .resourceURI)
        id = try c.decode(AttorneyID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        contactRaw = try c.decode(String.self, forKey: .contactRaw)
        dateCreated = try c.decode(Date.self, forKey: .dateCreated)
        dateModified = try c.decode(Date.self, forKey: .dateModified)
        phone = try Self.optionalContact(from: c, key: .phone) { try PhoneNumber($0) }
        fax  = try Self.optionalContact(from: c, key: .fax)   { try PhoneNumber($0) }
        email = try Self.optionalContact(from: c, key: .email) { try EmailAddress($0) }
    }

    public init(
        resourceURI: URL,
        id: AttorneyID,
        name: String,
        contactRaw: String,
        phone: PhoneNumber?,
        fax: PhoneNumber?,
        email: EmailAddress?,
        dateCreated: Date,
        dateModified: Date
    ) {
        self.resourceURI = resourceURI
        self.id = id
        self.name = name
        self.contactRaw = contactRaw
        self.phone = phone
        self.fax = fax
        self.email = email
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    // Decodes a string field: absent/blank → nil, non-blank → constructed via closure.
    // Using a closure avoids decoding the JSON value twice while staying generic.
    private static func optionalContact<T>(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys,
        construct: (String) throws -> T
    ) throws -> T? {
        guard let raw = try container.decodeIfPresent(String.self, forKey: key),
              !raw.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        return try construct(raw)
    }
}

#if DEBUG
extension Attorney {
    public enum TestData {
        public static let sampleAttorney = Attorney(
            resourceURI: URL(string: "https://www.courtlistener.com/api/rest/v4/attorneys/5001/")!,
            id: try! AttorneyID(5001),
            name: "Jane Smith",
            contactRaw: "123 Main St, Washington DC 20001",
            phone: try! PhoneNumber("202-555-0100"),
            fax: nil,
            email: try! EmailAddress("jsmith@example.com"),
            dateCreated: Date(timeIntervalSince1970: 1_616_025_600),
            dateModified: Date(timeIntervalSince1970: 1_616_025_600)
        )
    }
}
#endif
