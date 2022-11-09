import Foundation

public struct Activity: Searchable, Hashable {

	/// The unique activity id.
	public var id: Int

	/// The type of activity this activity's `id` is related to.
	public var type: ActivityResultType?
	
	public init(id: Int, type: ActivityResultType?) {
		self.id = id
		self.type = type
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
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}
