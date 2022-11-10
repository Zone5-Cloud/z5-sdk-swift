import Foundation

public struct Activity: Searchable, Hashable {

	/// The unique activity id.
	public var id: Int

	/// The type of activity this activity's `id` is related to.
	public var type: ActivityResultType?

	/// The sport related to this activity.
	public var sport: ActivityType?

	public init(id: Int, type: ActivityResultType?, sport: ActivityType?) {
		self.id = id
		self.type = type
		self.sport = sport
	}

	// MARK: Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(type)
	}

	// MARK: Codable

	public enum CodingKeys: String, Codable, CodingKey, CaseIterable {
		case id
		case type
		case sport
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}
