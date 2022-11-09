import Foundation

/// This is derived from the original VTeamMultiRidePeriod impl - it is used on aggregate reporting focused endpoints
public struct SearchInputReport: JSONEncodedBody, SearchInputCriteria {

	public var type: ActivityType?

	public var isAllTime: Bool?

	// /// Percentages - ie for use with days since last peak within X%
	// public var withinPercentages: [Int]?

	// public var period: AggregatePeriod?

	// public var depth: Int?

	public var userIDs: [Int64]?

	// public var groupID: Int?

	public var ranges: [DateRange]?
	
	/// Limit the search to UserBike.uuid
	public var bikeUids: [String]?

	// public var teamActivities: [VTeamActivity]?

	public var activities: [Activity]?

	/// Only include results related to these activities
	public var limit: [Activity]?

	public var groupBy: String?

	// public var exclude: VTeamMultiRidePeriod?

	// public var flag1: Bool?

	// public var flag2: Bool?

	// public var flag3: Bool?

	// public var extName: Bool?

	// public var noCache: Bool?

	// public var returnIDs: Bool?

	/// Flag that indicates if the search is inclusive (true) or exclusive (false).
	public var isInclusive: Bool?

	public var range: DateRange?

	private var opts: Int?

	/// Option to include zones - defaults to true and used in power curve
	public var shouldIncludeZones: Bool?

	public var references: [RelativePeriod]?

	/// Simple field list
	public var simpleFields: [String]?

	public var isNotNull: [String]?

	public var isNull: [String]?

	public var order: [Order]?

	// public var tags: Set<String>?

	public init() {
		opts = 3
		// search.opts = search.opts | (1 << 0); // set that we don't need the verbose field mapping
		// search.opts = search.opts | (1 << 1); // set a no-cache flag for this search
		// search.opts = search.opts | (1 << 3); // set a no-decorate flag for this search
	}

	// MARK: Creating reports

	/// Return a `SearchInputReport` which can be used for reporting endpoints, i.e. time in zone for a given activity.
	/// - Parameters:
	///   - activityType: The type of the activity we want a report on.
	///   - identifier: The id of the activity we want a report on.
	public static func forInstance(activityType: ActivityResultType, identifier: Int) -> SearchInputReport {
		var report = self.init()
		report.opts = 3
		report.activities = [Activity(id: identifier, type: activityType)]
		return report
    }

	/// Return a `SearchInputReport` which can be used for peak curve reporting endpoints.
	/// - Parameters:
	///   - activityType: The type of the activity we want a report on.
	///   - identifier: The id of the activity we want a report on.
	///   - referencePeriod: The comparison period to be included.
	public static func forInstancePeaksCurve(activityType: ActivityResultType, identifier: Int, referencePeriod: RelativePeriod?) -> SearchInputReport {
		var report = forInstance(activityType: activityType, identifier: identifier)

		if let referencePeriod = referencePeriod {
			report.references = [referencePeriod]
			report.isAllTime = true
		}

		return report
	}

	public static func forInstanceMetrics(sport: ActivityType, userIDs: [Int64], ranges: [DateRange], fields: [String]) -> SearchInput<SearchInputReport> {
		precondition(!userIDs.isEmpty, "At least one user ID must be set.")
		precondition(!fields.isEmpty, "At least one field must be set.")

		var ranges = ranges
		if ranges.isEmpty {
			ranges.append(DateRange(floor: Date(timeIntervalSince1970: 0), ceiling: Date()))
		}

		var report = self.init()
		report.userIDs = userIDs
		report.ranges = ranges
		report.type = sport

		var input = SearchInput(criteria: report)
		input.fields = fields
		input.options = 3

		return input
	}
	
	/// Build a metrics API query grouped by bike uuids - ie get summary stats by bike
	/// ranges can be empty and will defult to all time
	/// fields should not be empty. Must be at least one field
	/// bikeUids should not be empty.
	public static func forInstanceMetricsBikes(ranges: [DateRange], fields: [String], bikeUids: [String]) -> SearchInput<SearchInputReport> {
		precondition(!fields.isEmpty, "At least one field must be set.")
		precondition(!bikeUids.isEmpty, "At least one bike UUID must be set.")

		var report = self.init()
		report.bikeUids = bikeUids
		report.type = .ride // we are searching by bike. This can only be rides.
		if !ranges.isEmpty {
			report.ranges = ranges
		}
		report.groupBy = "bike.bikeUuid"

		var input = SearchInput(criteria: report)
		input.fields = fields
		input.options = 3

		return input
	}

	// MARK: Codable

	private enum CodingKeys: String, Codable, CodingKey {
		case type
		case isAllTime = "alltime"
		//case withinPercentages = "withinP"
		//case period
		//case depth
		case userIDs = "userIds"
		//case groupID = "groupId"
		case ranges
		case bikeUids
		//case teamActivities = "teamactivities"
		case activities
		case limit
		case groupBy
		//case exclude
		//case flag1
		//case flag2
		//case flag3
		//case extName
		//case noCache
		//case returnIDs = "returnIds"
		case isInclusive = "in"
		case range
		case opts
		case shouldIncludeZones = "incZones"
		case references
		case simpleFields = "sfields"
		case isNotNull
		case isNull
		case order
		//case tags
	}

}
