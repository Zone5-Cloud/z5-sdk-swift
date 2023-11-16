import Foundation

public struct ThirdPartyUploadResult: Searchable {
    public var stravaId: Int?
    public var komootId: Int?

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case stravaId = "stravaId"
        case komootId = "komootId"
    }

    public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
        mapFieldsToSearchStrings(fields: fields, prefix: prefix)
    }
}
