import Foundation

/// Model object representing a User
public struct User: Searchable, JSONEncodedBody {

	/// Unique user id (within Z5/TP database)
	public var id: Int?

	/// Unique user uuid within single sign on domain
	public var uuid: String?
	
	/// User's log in password
	public var password: String?

	/// Unique email address
	public var email: String?

	public var firstName: String?

	public var lastName: String?

	/// URL to an avatar image
	public var avatar: URL?
	
	/// User's Locale
	public var locale: String?
	
	public var timezone: String?
	
	public var identities: [String: String]?
	
	public var weight: Double?
	
	public var gender: String?
	
	public var isValidated: Bool?
	
	public var isSuspended: Bool?
	
	public var createdTime: Milliseconds?
	public var lastLogin: Milliseconds?
	
	public var metric: UnitMeasurement?

	public init() { }
	public init(email: String, password: String, firstname: String, lastname: String) {
		self.email = email
		self.password = password
		self.firstName = firstname
		self.lastName = lastname
	}

	// MARK: Codable

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case id
		case uuid
		case password
		case email
		case firstName = "firstname"
		case lastName = "lastname"
		case avatar
		case locale
		case timezone
		case identities
		case weight
		case gender
		case isValidated = "validated"
		case isSuspended = "suspended"
		case createdTime
		case lastLogin
		case metric		
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}
