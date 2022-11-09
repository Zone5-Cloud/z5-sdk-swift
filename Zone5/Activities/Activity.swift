import Foundation

public struct Activity: Searchable, Hashable {

	/// The unique activity id.
	public var id: Int

	/// The type of activity this activity's `id` is related to.
	public var activity: ActivityResultType?

	/// The sport related to this activity.
	public var type: ActivityType?
	
	public init(id: Int, activity: ActivityResultType?, type: ActivityType?) {
		self.id = id
		self.activity = activity
		self.type = type
	}

	// MARK: Hashable

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(activity)
	}

	// MARK: Codable

	public enum CodingKeys: String, Codable, CodingKey, CaseIterable {
		case id
		case activity
		case type
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}
