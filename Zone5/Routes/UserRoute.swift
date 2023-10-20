import Foundation

/// Protocol that allows a route's ID or UUID values to be used interchangeably when accessing API endpoints.
public protocol UserRouteServerIdentifier: CustomStringConvertible {}

public struct UserRoute: Searchable, JSONEncodedBody {

	public typealias Identifier = Int
	public typealias UUID = String

	public var id: Identifier?

	public var uuid: UUID?

	/// When this object was first created
	public var createdTime: Milliseconds?

	/// When this object was last modified
	public var modifiedTime: Milliseconds?

	/// Who created this object
	public var createdBy: String?

	/// Who last modified this object
	public var modifiedBy: String?

	/// Who owns this object
	public var user: User?

	// public var company: VCompany?

	/// The number of times this route should be completed
	public var repeatCount: Int?

	/// A nice name for this route
	public var name: String?

	/// The origin of how this route came into the system. ie created manually, cloned from an activity, synced from Strava etc
	public var source: String?

	/// The original UUID/id of this route in it's origin system
	public var sourceID: String?

	/// The locality of where this route begins
	public var locality: String?

	/// The mid locality of this route
	public var locality1: String?

	/// The locality of where this route ends
	public var locality2: String?

	/// The language that the waypoint messages are in
	public var locale: String?

	/// The metric/imperial that the way point messages are in
	public var units: UnitMeasurement?

	/// A description of this route
	public var description: String?

	/// The total distance (meters) of this route
	public var distance: Double?

	/// The total elevation gain (meters) of this route
	public var ascent: Int?

	/// The total elevation loss (meters) of this route
	public var descent: Int?

	/// The estimated time for this route (seconds)
	public var duration: Int?

	/// The lowest altitude point in this route (meters)
	public var minimumAltitude: Int?

	/// The highest altitude point in this route (meters)
	public var maximumAltitude: Int?

	/// The average altitude point in this route (meters)
	public var averageAltitude: Int?

	/// Min latitude in this route - for geo boxing
	public var minimumLatitude: Int?

	/// Min longitude in this route - for geo boxing
	public var minimumLongitude: Int?

	/// Max latitude in this route - for geo boxing
	public var maximumLatitude: Int?

	/// Max longitude in this route - for geo boxing
	public var maximumLongitude: Int?

	/// The sport type for this route - ie cycling, running etc
	public var type: ActivityType?

	/// The recommended cycling equipment for this route - ie TT, road, mtb etc
	public var equipment: Set<Equipment>?

	/// User type of terrain in this route
	public var terrain: Set<Terrain>?

	/// User defined tags for this route
	public var tags: Set<String>?

	///// Use for tracking favorite etc
	//public var mask: Int?

	/// A bitmask used for tracking visibility / sharing of this route - see UserRouteVisibilityMask
	public var visibilityMask: Int?

	/// Permissions which the current user has scope to on this object
	public var permissions: Set<String>?

	/// The processing state - used when a route is imported or cloned from another source
	public var state: FileUploadState?

	/// Any processing / import error message (if any)
	public var message: String?

	/// Start location
	public var latitude1: Double?
	public var longitude1: Double?

	/// End location
	public var latitude2: Double?
	public var longitude2: Double?

	/// My rating of this route (if any)
	public var rating: Int?

	/// The overall rating of this route (if any)
	public var publicRatingOverall: Int?

	/// The number of public ratings (if any)
	public var publicRatingCount: Int?

	public init() {}

	// MARK: Codable

	public enum CodingKeys: String, CodingKey, CaseIterable {
			case id
			case uuid
			case createdTime
			case modifiedTime = "modifedTime"
			case createdBy
			case modifiedBy = "modifedBy"
			case user
			//case company
			case repeatCount = "rpt"
			case name
			case source
			case sourceID = "sourceId"
			case locality
			case locality1
			case locality2
			case locale
			case units
			case description
			case distance
			case ascent
			case descent
			case duration
			case minimumAltitude = "minAlt"
			case maximumAltitude = "maxAlt"
			case averageAltitude = "avgAlt"
			case minimumLatitude = "minLatitude"
			case minimumLongitude = "minIntitude"
			case maximumLatitude = "maxLatitude"
			case maximumLongitude = "maxIntitude"
			case type
			case equipment
			case terrain
			case tags
			//case mask
			case visibilityMask = "vmask"
			case permissions
			case state
			case message
			case latitude1 = "lat1"
			case longitude1 = "lon1"
			case latitude2 = "lat2"
			case longitude2 = "lon2"
			case rating
			case publicRatingOverall = "publicRating"
			case publicRatingCount = "publicRatingCnt"
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}

extension UserRoute.Identifier: UserRouteServerIdentifier {}

extension UserRoute.UUID: UserRouteServerIdentifier {}
