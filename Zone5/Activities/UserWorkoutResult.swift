import Foundation

/// This is a view object related to activity data. It has a lot of possible fields, but most are only populated if a
/// specific field is requested via the Activities API.
///
/// Some fields are also sport specific - and will only be set on activities of the relevant sport type.
public struct UserWorkoutResult: Searchable {

	/// UserWorkoutResult.id
	public var id: Int?

	/// The year that this activity was completed
	public var year: Int?

	/// The day of year that this activity was completed
	public var dayOfYear: Int?

	/// A unix timestamp (ms) of when this activity was last modified
	public var modifiedTime: Milliseconds?

	/// A unix timestamp (ms) of when this activity was created in the system (not the actual activity start time)
	public var createdTime: Milliseconds?

	/// Flag to track if this workout is tagged as a favorite/bookmarked
	public var favorite: Bool?

	/// Metadata on the head unit used to complete this activity
	public var headunit: UserHeadunit?

	/// Metadata on the power meter used to complete this activity
	public var powerMeter: UserPowerMeter?

	/// A generic count param - often used to convey the number of records which comprise an aggregate calculation
	public var count: Int?

	/// Metadata related to day attributes on the day this activity was scheduled/completed
	//public var day: VUserDay?

	/// Metadata related to HRV on the day this activity was scheduled/completed
	//public var hrv: VUserDayHRV?

	/// Metadata related to sleep on the day this activity was scheduled/completed
	//public var sleep: VUserDaySleep?

	/// Metadata related to subjective ratings completed on the day this activity was scheduled/completed
	//public var rating: VUserDayRatings?

	/// Metadata related to route used for this activity
	public var route: UserRoute?

	/// Rating of the scheduled workout
	//public var sessionRating: VUserWorkoutResultRating?

	/// Metadata related to a scheduled workout/event
	public var scheduled: UserWorkoutDetails?

	/// Metadata related to a scheduled workout/event
	//public var event: VUserEvent?

	/// Metadata related to the training plan this activity relates to
	//public var plan: VUserPlan?

	/// A flag indicating how this activity result came into the system
	public var source: ResultSource?

	/// Locality based of geolocation data
	public var locality: String?

	/// A bitmask tracking which fields have been manually modified in the activity results
	public var fieldOverrideMask: Int?

	/// A bitmask tracking which fields have been manually modified in the activity results
	public var fieldOverrideMask2: Int?

	/// A bitmask tracking potential data integrity issues with this activity data
	public var reviewMask: Int?

	/// A bitmask tracking which data channels are available in this activity
	public var channelMask: Int?

	/// A bitmask tracking which file processing features have run
	public var featureMask: Int?

	/// A bitmask tracking which time in zones have been calculated for this activity
	public var zoneMask: Int?

	public var notes: Int?

	public var user: User?

	/// Start location of the activity
	public var startLatitude: Double?
	/// Start location of the activity
	public var startLongitude: Double?

	/// End location of the activity
	public var endLatitude: Double?
	/// End location of the activity
	public var endLongitude: Double?

	/// Power efficiency - a relation of power to heart rate
	public var efficiency: Double?

	/// ascent / training/60/60
	public var vam: Double?

	/// subjective rating - rate of perceived effort
	public var rpe: Double?

	/// subjective rating - pain score / leg quality score
	public var pain: Double?

	/// subjective rating - total quality recovery
	public var tqr: Double?

	/// Avg torque (nm)
	public var averageNm: Int?

	/// Max torque (nm)
	public var maximumNm: Int?

	/// Cafe time - time difference between training and elapsed time (seconds)
	public var idle: Int?

	/// Number of seconds where no power was being produced
	public var noPower: TimeInterval?

	/// avg Power / Heart Rate / RPE/// 1000
	public var gscore: Int?

	/// average heart rate / RPE
	public var rpeh: Double?

	/// aPower:HR (altitude corrected average power / average heart rate)
	public var rpeef: Double?

	/// aPower:RPE (altitude corrected average power / RPE)
	public var rpep: Double?

	/// State of the workout - ie completed, did not start, pending etc
	public var state: UserWorkoutState?

	/// Flag for tracking whether this activity has been reviewed or has data integrity issues
	public var review: ResultReview?

	/// Reason why a workout was not completed
	public var reason: UserWorkoutFailedReason?

	/// Activity name
	public var name: String?

	/// Activity description
	public var description: String?

	/// Display name for the event course
	public var course: String?

	/// Event category
	public var category: EventTeamCategory?

	/// UserWorkout.id - if this result relates to a workout
	public var workoutID: Int?

	/// UserWorkoutFile.id - if this result relates to a file
	public var fileID: Int?

	/// UserEvent.id - if this result relates to an event
	public var eventID: Int?

	/// This id coupled with the ActivityResultType is a unique key for this activity
	public var activityID: Int?

	/// This value coupled with the activityId is a unique key for this activity
	public var activity: ActivityResultType?

	/// Timestamp of the result - this will match either the workout or event scheduled date or the start time of an adhoc ride
	public var timestamp: Milliseconds?

	/// Timestamp of when the activity actually commenced
	public var startTime: Milliseconds?

	/// The timezone this activity is scheduled or completed in
	public var timeZone: String?

	/// Type of activity - ie ride, run etc
	public var type: ActivityType?

	/// Equipment used in the activity (cycling)
	public var equipment: Equipment?

	/// Type of workout - ie training, event etc
	public var workout: WorkoutType?

	/// Lap number (if any - only set on intervals)
	public var lap: Int?

	/// Lap type (if any - only set on intervals)
	public var lapType: LapType?

	/// The user's weight at the time of the activity (kg)
	public var weight: Double?

	/// Actual movement time (seconds)
	public var training: TimeInterval?

	/// Elapsed time (seconds)
	public var elapsed: TimeInterval?

	public var vo2max: Double?

	/// Total distance
	public var distance: Double?

	/// Power based T-Score
	public var tscorepwr: Double?

	/// Heart rate based T-Score
	public var tscorehr: Double?

	/// Threshold heart rate
	public var atBpm: Int?

	/// Intensity factor
	public var intensityFactor: Int?

	/// Estimated calories for the activity
	public var calories: Int?

	/// Estimated kj for the activity
	public var kj: Int?

	/// Estimated kj/hour for the activity
	public var kjh: Double?

	/// Estimated kj/body weight (kg) for the activity
	public var kjkg: Double?

	/// Estimated kj/h/kg for the activity
	public var kjhkg: Double?

	/// Adjusted power for the activity
	public var np: Int?

	/// Variability index for the activity
	public var vi: Double?

	/// Intensity for the activity
	public var iff: Double?

	/// watts/kg
	public var wkg: Double?

	/// The threshold power when this activity was completed
	public var thresholdWatts: Int?

	/// The estimated threshold based on this activity
	public var estimatedThresholdWatts: Int?

	public var estimatedThresholdWattsKg: Int?

	/// The threshold type used for this activity
	public var thresholdType: PowerThresholdType?

	/// The tscore calculation used for this activity
	public var tscoreType: TScoreType?

	/// The threshold heart rate when this activity was completed
	public var thresholdBpm: Int?

	/// The threshold pace when this activity was completed
	public var thresholdPace: Int?

	/// The max heart rate set when this activity was completed (ie user profile maxHr, not the peak heart rate in the activity
	public var maxHr: Int?

	/// Total elevation gain
	public var ascent: Int?

	/// Total elevation loss
	public var descent: Int?

	/// Starting altitude
	public var startAltitude: Int?

	/// Finishing altitude
	public var endAltitude: Int?

	/// Min altitude
	public var minimumAltitude: Int?

	/// Max altitude
	public var maximumAltitude: Int?

	/// Average altitude
	public var averageAltitude: Int?

	/// Speed (km/h)
	public var averageSpeed: Double?

	/// Speed (km/h)
	public var maximumSpeed: Double?

	/// Cadence (rpm)
	public var averageCadence: Int?

	/// Cadence (rpm)
	public var maximumCadence: Int?

	/// Saturated Hb percent
	public var minimumSaturatedHbPercent: Double?
	/// Saturated Hb percent
	public var maximumSaturatedHbPercent: Double?
	/// Saturated Hb percent
	public var averageSaturatedHbPercent: Double?

	/// TotalHemoglobinConc
	public var minimumTotalHbConc: Double?
	/// TotalHemoglobinConc
	public var maximumTotalHbConc: Double?
	/// TotalHemoglobinConc
	public var averageTotalHbConc: Double?

	/// Temperature (celsius)
	public var minimumTemperature: Int?
	/// Temperature (celsius)
	public var maximumTemperature: Int?
	/// Temperature (celsius)
	public var averageTemperature: Int?

	/// Heart rate (BPM)
	public var minimumBpm: Int?
	/// Heart rate (BPM)
	public var averageBpm: Int?
	/// Heart rate (BPM)
	public var maximumBpm: Int?

	/// Percentage of maxHR
	public var averageBpmP: Double?

	/// Percentage of maxHR
	public var maximumBpmP: Double?

	/// Average power
	public var averageWatts: Int?

	/// Estimated critical power
	public var cp: Int?

	/// Anaerobic work capacity - Joules
	public var awc: Int?

	public var tau: Double?

	/// Average power above threshold
	public var averageWattsAboveCP: Int?

	/// Average power below threshold
	public var averageWattsBelowCP: Int?

	/// Time above threshold
	public var timeAboveCP: Int?

	/// Maximum power
	public var maximumWatts: Int?

	public var peak3SecondWatts: Int?
	public var peak3SecondWattsPercentage: Int?
	public var peak3SecondWkg: Double?

	public var peak4SecondWatts: Int?
	public var peak4SecondWattsPercentage: Int?
	public var peak4SecondWkg: Double?

	public var peak5SecondWatts: Int?
	public var peak5SecondWattsPercentage: Int?
	public var peak5SecondWkg: Double?

	public var peak10SecondWatts: Int?
	public var peak10SecondWattsPercentage: Int?
	public var peak10SecondWkg: Double?

	public var peak12SecondWatts: Int?
	public var peak12SecondWattsPercentage: Int?
	public var peak12SecondWkg: Double?

	public var peak20SecondWatts: Int?
	public var peak20SecondWattsPercentage: Int?
	public var peak20SecondWkg: Double?

	public var peak30SecondWatts: Int?
	public var peak30SecondWattsPercentage: Int?
	public var peak30SecondWkg: Double?

	public var peak1MinuteWatts: Int?
	public var peak1MinuteWattsPercentage: Int?
	public var peak1MinuteWkg: Double?

	public var peak2MinuteWatts: Int?
	public var peak2MinuteWattsPercentage: Int?
	public var peak2MinuteWkg: Double?

	public var peak3MinuteWatts: Int?
	public var peak3MinuteWattsPercentage: Int?
	public var peak3MinuteWkg: Double?

	public var peak4MinuteWatts: Int?
	public var peak4MinuteWattsPercentage: Int?
	public var peak4MinuteWkg: Double?

	public var peak5MinuteWatts: Int?
	public var peak5MinuteWattsPercentage: Int?
	public var peak5MinuteWkg: Double?

	public var peak6MinuteWatts: Int?
	public var peak6MinuteWattsPercentage: Int?
	public var peak6MinuteWkg: Double?

	public var peak10minWatts: Int?
	public var peak10minWattsPercentage: Int?
	public var peak10minWkg: Double?

	public var peak12MinuteWatts: Int?
	public var peak12MinuteWattsPercentage: Int?
	public var peak12MinuteWkg: Double?

	public var peak15MinuteWatts: Int?
	public var peak15MinuteWattsPercentage: Int?
	public var peak15MinuteWkg: Double?

	public var peak16MinuteWatts: Int?
	public var peak16MinuteWattsPercentage: Int?
	public var peak16MinuteWkg: Double?

	public var peak20MinuteWatts: Int?
	public var peak20MinuteWattsPercentage: Int?
	public var peak20MinuteWkg: Double?

	public var peak24MinuteWatts: Int?
	public var peak24MinuteWattsPercentage: Int?
	public var peak24MinuteWkg: Double?

	public var peak30MinuteWatts: Int?
	public var peak30MinuteWattsPercentage: Int?
	public var peak30MinuteWkg: Double?

	public var peak40MinuteWatts: Int?
	public var peak40MinuteWattsPercentage: Int?
	public var peak40MinuteWkg: Double?

	public var peak60MinuteWatts: Int?
	public var peak60MinuteWattsPercentage: Int?
	public var peak60MinuteWkg: Double?

	public var peak75MinuteWatts: Int?
	public var peak75MinuteWattsPercentage: Int?
	public var peak75MinuteWkg: Double?

	public var peak80MinuteWatts: Int?
	public var peak80MinuteWattsPercentage: Int?
	public var peak80MinuteWkg: Double?

	public var peak90MinuteWatts: Int?
	public var peak90MinuteWattsPercentage: Int?
	public var peak90MinuteWkg: Double?

	public var peak120MinuteWatts: Int?
	public var peak120MinuteWattsPercentage: Int?
	public var peak120MinuteWkg: Double?

	public var peak150MinuteWatts: Int?
	public var peak150MinuteWattsPercentage: Int?
	public var peak150MinuteWkg: Double?

	public var peak180MinuteWatts: Int?
	public var peak180MinuteWattsPercentage: Int?
	public var peak180MinuteWkg: Double?

	public var peak210MinuteWatts: Int?
	public var peak210MinuteWattsPercentage: Int?
	public var peak210MinuteWkg: Double?

	public var peak240MinuteWatts: Int?
	public var peak240MinuteWattsPercentage: Int?
	public var peak240MinuteWkg: Double?

	public var peak360MinuteWatts: Int?
	public var peak360MinuteWattsPercentage: Int?
	public var peak360MinuteWkg: Double?

	public var peak5SecondBpm: Int?
	public var peak5SecondBpmPercentage: Int?

	public var peak10SecondBpm: Int?
	public var peak10SecondBpmPercentage: Int?

	public var peak1MinuteBpm: Int?
	public var peak1MinuteBpmPercentage: Int?

	public var peak5MinuteBpm: Int?
	public var peak5MinuteBpmPercentage: Int?

	public var peak10MinuteBpm: Int?
	public var peak10MinuteBpmPercentage: Int?

	public var peak20MinuteBpm: Int?
	public var peak20MinuteBpmPercentage: Int?

	public var peak30MinuteBpm: Int?
	public var peak30MinuteBpmPercentage: Int?

	public var peak60MinuteBpm: Int?
	public var peak60MinuteBpmPercentage: Int?

	public var peak120MinuteBpm: Int?
	public var peak120MinuteBpmPercentage: Int?

	public var peak180MinuteBpm: Int?
	public var peak180MinuteBpmPercentage: Int?

	/// di2 gearing
	public var minimumGear: String?
	public var maximumGear: String?
	public var averageGear: String?
	public var gearChangeCount: Int?

	/// gradient %
	public var minimumGrade: Double?
	public var maximumGrade: Double?
	public var averageGrade: Double?

	public var bpmSampleRate: Double?
	public var bpmSampleCount: Int?

	public var powerSampleRate: Double?
	public var powerSampleCount: Int?

	/// power meter info
	public var powerDisplay: String?
	public var powerBattery: Double?
	public var powerBatteryPercentage: Int?
	public var powerOffset: Int?
	public var powerSlope: Int?
	public var powerManufacturer: String?
	public var powerManufacturerId: Int?
	public var powerVersion: String?
	public var powerSerial: String?
	public var powerProduct: String?
	public var powerID: String?
	public var powerBalance: Int?
	public var powerDiscardCount: Int?

	/// Time in zones
	public var secondsInZonePower: [Int: TimeInterval]?
	public var secondsInSurface: [String: TimeInterval]?
	public var secondsInZonePace: [Int: TimeInterval]?
	public var secondsInZoneWkg: [Int: TimeInterval]?
	public var secondsInZoneNm: [Int: TimeInterval]?
	public var secondsInZoneBpm: [Int: TimeInterval]?
	public var secondsInZoneMaxHr: [Int: TimeInterval]?

	public var wkgZones: [UserIntensityZoneRange]?
	public var bpmZones: [UserIntensityZoneRange]?
	public var maxHrZones: [UserIntensityZoneRange]?
	public var powerZones: [UserIntensityZoneRange]?
	public var nmZones: [UserIntensityZoneRange]?
	public var paceZones: [UserIntensityZoneRange]?
	public var bpmZoneNames: [Int: String]?

	public var laps: [UserWorkoutResult]?

	public var distributions: [DataFileChannel: [Int: Int]]?

	//public var swimLaps: [VUserWorkoutResultSwimLap]?

	/// used for multisport and brick? sub-activities
	public var children: [UserWorkoutResult]?
	public var related: [UserWorkoutResult]?
	public var parent: Indirect<UserWorkoutResult>?

	//public var metadata: [String: Any]?

	public var permissions: [String]?

	public var aap: UserWorkoutResultAlt?

	public var `extension`: UserWorkoutResultExt?

	public var extension2: UserWorkoutResultExt2?

	public var pace: UserWorkoutResultPeakPace?

	public var lss: UserWorkoutResultPeakLss?

	public var hour: UserWorkoutResultByHour?

	public var turbo: UserWorkoutResultTurbo?
	
	public var turboExt: UserWorkoutResultTurboExt?
	
	public var bike: UserWorkoutResultBike?

	public var channels: [UserWorkoutResultChannel]?

	// MARK: UserWorkoutResultAggregates

	public var sum: Indirect<UserWorkoutResult>?
	public var minimum: Indirect<UserWorkoutResult>?
	public var maximum: Indirect<UserWorkoutResult>?
	public var average: Indirect<UserWorkoutResult>?
	public var weightedAverage: Indirect<UserWorkoutResult>?

	public init() {}

	// MARK: Codable

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case id = "id"
		case year = "year"
		case dayOfYear = "dayOfYear"
		case modifiedTime = "modifedTime"
		case createdTime = "createdTime"
		case favorite = "favorite"
		case headunit = "headunit"
		case powerMeter = "powermeter"
		case count = "count"
		//case day = "day"
		//case hrv = "hrv"
		//case sleep = "sleep"
		//case rating = "rating"
		case route = "route"
		//case sessionRating = "sessionrating"
		case scheduled = "scheduled"
		//case event = "event"
		//case plan = "plan"
		case source = "source"
		case locality = "locality"
		case fieldOverrideMask = "fieldOverrideMask"
		case fieldOverrideMask2 = "fieldOverrideMask2"
		case reviewMask = "reviewMask"
		case channelMask = "channelMask"
		case featureMask = "featureMask"
		case zoneMask = "zoneMask"
		case notes = "notes"
		case user = "user"
		case startLatitude = "lat1"
		case startLongitude = "lon1"
		case endLatitude = "lat2"
		case endLongitude = "lon2"
		case efficiency = "ef"
		case vam = "vam"
		case rpe = "rpe"
		case pain = "pain"
		case tqr = "tqr"
		case averageNm = "avgNm"
		case maximumNm = "maxNm"
		case idle = "idle"
		case noPower = "noPower"
		case gscore = "gscore"
		case rpeh = "rpeh"
		case rpeef = "rpeef"
		case rpep = "rpep"
		case state = "state"
		case review = "review"
		case reason = "reason"
		case name = "name"
		case description = "descr"
		case course = "course"
		case category = "category"
		case workoutID = "workoutId"
		case fileID = "fileId"
		case eventID = "eventId"
		case activityID = "activityId"
		case activity = "activity"
		case timestamp = "ts"
		case startTime = "startTs"
		case timeZone = "tz"
		case type = "type"
		case equipment = "equipment"
		case workout = "workout"
		case lap = "lap"
		case lapType = "lapType"
		case weight = "weight"
		case training = "training"
		case elapsed = "elapsed"
		case vo2max = "vo2max"
		case distance = "distance"
		case tscorepwr = "tscorepwr"
		case tscorehr = "tscorehr"
		case atBpm = "atBpm"
		case intensityFactor = "intensityFactor"
		case calories = "calories"
		case kj = "kj"
		case kjh = "kjh"
		case kjkg = "kjkg"
		case kjhkg = "kjhkg"
		case np = "np"
		case vi = "vi"
		case iff = "iff"
		case wkg = "wkg"
		case thresholdWatts = "thresholdWatts"
		case estimatedThresholdWatts = "estThresWatts"
		case estimatedThresholdWattsKg = "estThresWattsKg"
		case thresholdType = "thresholdType"
		case tscoreType = "tscoreType"
		case thresholdBpm = "thresholdBpm"
		case thresholdPace = "thresholdPace"
		case maxHr = "maxHr"
		case ascent = "ascent"
		case descent = "descent"
		case startAltitude = "startAlt"
		case endAltitude = "endAlt"
		case minimumAltitude = "minAlt"
		case maximumAltitude = "maxAlt"
		case averageAltitude = "avgAlt"
		case averageSpeed = "avgSpeed"
		case maximumSpeed = "maxSpeed"
		case averageCadence = "avgCadence"
		case maximumCadence = "maxCadence"
		case minimumSaturatedHbPercent = "minSatHbP"
		case maximumSaturatedHbPercent = "maxSatHbP"
		case averageSaturatedHbPercent = "avgSatHbP"
		case minimumTotalHbConc = "minTotHbC"
		case maximumTotalHbConc = "maxTotHbC"
		case averageTotalHbConc = "avgTotHbC"
		case minimumTemperature = "minTemp"
		case maximumTemperature = "maxTemp"
		case averageTemperature = "avgTemp"
		case minimumBpm = "minBpm"
		case averageBpm = "avgBpm"
		case maximumBpm = "maxBpm"
		case averageBpmP = "avgBpmP"
		case maximumBpmP = "maxBpmP"
		case averageWatts = "avgWatts"
		case cp = "cp"
		case awc = "awc"
		case tau = "tau"
		case averageWattsAboveCP = "avgWattsAboveCP"
		case averageWattsBelowCP = "avgWattsBelowCP"
		case timeAboveCP = "timeAboveCP"
		case maximumWatts = "maxWatts"
		case peak3SecondWatts = "peak3secWatts"
		case peak3SecondWattsPercentage = "peak3secWattsP"
		case peak3SecondWkg = "peak3secWkg"
		case peak4SecondWatts = "peak4secWatts"
		case peak4SecondWattsPercentage = "peak4secWattsP"
		case peak4SecondWkg = "peak4secWkg"
		case peak5SecondWatts = "peak5secWatts"
		case peak5SecondWattsPercentage = "peak5secWattsP"
		case peak5SecondWkg = "peak5secWkg"
		case peak10SecondWatts = "peak10secWatts"
		case peak10SecondWattsPercentage = "peak10secWattsP"
		case peak10SecondWkg = "peak10secWkg"
		case peak12SecondWatts = "peak12secWatts"
		case peak12SecondWattsPercentage = "peak12secWattsP"
		case peak12SecondWkg = "peak12secWkg"
		case peak20SecondWatts = "peak20secWatts"
		case peak20SecondWattsPercentage = "peak20secWattsP"
		case peak20SecondWkg = "peak20secWkg"
		case peak30SecondWatts = "peak30secWatts"
		case peak30SecondWattsPercentage = "peak30secWattsP"
		case peak30SecondWkg = "peak30secWkg"
		case peak1MinuteWatts = "peak1minWatts"
		case peak1MinuteWattsPercentage = "peak1minWattsP"
		case peak1MinuteWkg = "peak1minWkg"
		case peak2MinuteWatts = "peak2minWatts"
		case peak2MinuteWattsPercentage = "peak2minWattsP"
		case peak2MinuteWkg = "peak2minWkg"
		case peak3MinuteWatts = "peak3minWatts"
		case peak3MinuteWattsPercentage = "peak3minWattsP"
		case peak3MinuteWkg = "peak3minWkg"
		case peak4MinuteWatts = "peak4minWatts"
		case peak4MinuteWattsPercentage = "peak4minWattsP"
		case peak4MinuteWkg = "peak4minWkg"
		case peak5MinuteWatts = "peak5minWatts"
		case peak5MinuteWattsPercentage = "peak5minWattsP"
		case peak5MinuteWkg = "peak5minWkg"
		case peak6MinuteWatts = "peak6minWatts"
		case peak6MinuteWattsPercentage = "peak6minWattsP"
		case peak6MinuteWkg = "peak6minWkg"
		case peak10minWatts = "peak10minWatts"
		case peak10minWattsPercentage = "peak10minWattsP"
		case peak10minWkg = "peak10minWkg"
		case peak12MinuteWatts = "peak12minWatts"
		case peak12MinuteWattsPercentage = "peak12minWattsP"
		case peak12MinuteWkg = "peak12minWkg"
		case peak15MinuteWatts = "peak15minWatts"
		case peak15MinuteWattsPercentage = "peak15minWattsP"
		case peak15MinuteWkg = "peak15minWkg"
		case peak16MinuteWatts = "peak16minWatts"
		case peak16MinuteWattsPercentage = "peak16minWattsP"
		case peak16MinuteWkg = "peak16minWkg"
		case peak20MinuteWatts = "peak20minWatts"
		case peak20MinuteWattsPercentage = "peak20minWattsP"
		case peak20MinuteWkg = "peak20minWkg"
		case peak24MinuteWatts = "peak24minWatts"
		case peak24MinuteWattsPercentage = "peak24minWattsP"
		case peak24MinuteWkg = "peak24minWkg"
		case peak30MinuteWatts = "peak30minWatts"
		case peak30MinuteWattsPercentage = "peak30minWattsP"
		case peak30MinuteWkg = "peak30minWkg"
		case peak40MinuteWatts = "peak40minWatts"
		case peak40MinuteWattsPercentage = "peak40minWattsP"
		case peak40MinuteWkg = "peak40minWkg"
		case peak60MinuteWatts = "peak60minWatts"
		case peak60MinuteWattsPercentage = "peak60minWattsP"
		case peak60MinuteWkg = "peak60minWkg"
		case peak75MinuteWatts = "peak75minWatts"
		case peak75MinuteWattsPercentage = "peak75minWattsP"
		case peak75MinuteWkg = "peak75minWkg"
		case peak80MinuteWatts = "peak80minWatts"
		case peak80MinuteWattsPercentage = "peak80minWattsP"
		case peak80MinuteWkg = "peak80minWkg"
		case peak90MinuteWatts = "peak90minWatts"
		case peak90MinuteWattsPercentage = "peak90minWattsP"
		case peak90MinuteWkg = "peak90minWkg"
		case peak120MinuteWatts = "peak120minWatts"
		case peak120MinuteWattsPercentage = "peak120minWattsP"
		case peak120MinuteWkg = "peak120minWkg"
		case peak150MinuteWatts = "peak150minWatts"
		case peak150MinuteWattsPercentage = "peak150minWattsP"
		case peak150MinuteWkg = "peak150minWkg"
		case peak180MinuteWatts = "peak180minWatts"
		case peak180MinuteWattsPercentage = "peak180minWattsP"
		case peak180MinuteWkg = "peak180minWkg"
		case peak210MinuteWatts = "peak210minWatts"
		case peak210MinuteWattsPercentage = "peak210minWattsP"
		case peak210MinuteWkg = "peak210minWkg"
		case peak240MinuteWatts = "peak240minWatts"
		case peak240MinuteWattsPercentage = "peak240minWattsP"
		case peak240MinuteWkg = "peak240minWkg"
		case peak360MinuteWatts = "peak360minWatts"
		case peak360MinuteWattsPercentage = "peak360minWattsP"
		case peak360MinuteWkg = "peak360minWkg"
		case peak5SecondBpm = "peak5secBpm"
		case peak5SecondBpmPercentage = "peak5secBpmP"
		case peak10SecondBpm = "peak10secBpm"
		case peak10SecondBpmPercentage = "peak10secBpmP"
		case peak1MinuteBpm = "peak1minBpm"
		case peak1MinuteBpmPercentage = "peak1minBpmP"
		case peak5MinuteBpm = "peak5minBpm"
		case peak5MinuteBpmPercentage = "peak5minBpmP"
		case peak10MinuteBpm = "peak10minBpm"
		case peak10MinuteBpmPercentage = "peak10minBpmP"
		case peak20MinuteBpm = "peak20minBpm"
		case peak20MinuteBpmPercentage = "peak20minBpmP"
		case peak30MinuteBpm = "peak30minBpm"
		case peak30MinuteBpmPercentage = "peak30minBpmP"
		case peak60MinuteBpm = "peak60minBpm"
		case peak60MinuteBpmPercentage = "peak60minBpmP"
		case peak120MinuteBpm = "peak120minBpm"
		case peak120MinuteBpmPercentage = "peak120minBpmP"
		case peak180MinuteBpm = "peak180minBpm"
		case peak180MinuteBpmPercentage = "peak180minBpmP"
		case minimumGear = "minGear"
		case maximumGear = "maxGear"
		case averageGear = "avgGear"
		case gearChangeCount = "gearChangeCnt"
		case minimumGrade = "minGrade"
		case maximumGrade = "maxGrade"
		case averageGrade = "avgGrade"
		case bpmSampleRate = "bpmSampleRate"
		case bpmSampleCount = "bpmSampleCnt"
		case powerSampleRate = "pwrSampleRate"
		case powerSampleCount = "pwrSampleCnt"
		case powerDisplay = "pwrDisplay"
		case powerBattery = "pwrBattery"
		case powerBatteryPercentage = "pwrBatteryP"
		case powerOffset = "pwrOffset"
		case powerSlope = "pwrSlope"
		case powerManufacturer = "pwrManufacturer"
		case powerManufacturerId = "pwrManufacturerId"
		case powerVersion = "pwrVersion"
		case powerSerial = "pwrSerial"
		case powerProduct = "pwrProduct"
		case powerID = "pwrId"
		case powerBalance = "pwrBalance"
		case powerDiscardCount = "pwrDiscardCnt"
		case secondsInZonePower = "secsInZonePwr"
		case secondsInSurface = "secsInSurface"
		case secondsInZonePace = "secsInZonePace"
		case secondsInZoneWkg = "secsInZoneWkg"
		case secondsInZoneNm = "secsInZoneNm"
		case secondsInZoneBpm = "secsInZoneBpm"
		case secondsInZoneMaxHr = "secsInZoneMaxHr"
		case wkgZones = "wkgZones"
		case bpmZones = "bpmZones"
		case maxHrZones = "maxHrZones"
		case powerZones = "pwrZones"
		case nmZones = "nmZones"
		case paceZones = "paceZones"
		case bpmZoneNames = "bpmZoneNames"
		case laps = "laps"
		case distributions = "distributions"
		//case swimLaps = "swimLaps"
		case children = "children"
		case related = "related"
		case parent = "parent"
		//case metadata = "metadata"
		case permissions = "permissions"
		case aap = "aap"
		case `extension` = "ext"
		case extension2 = "ext2"
		case pace = "pace"
		case lss = "lss"
		case hour = "hour"
		case turbo = "turbo"
		case turboExt = "turboExt"
		case bike = "bike"
		case channels = "channels"
		case sum = "sum"
		case minimum = "min"
		case maximum = "max"
		case average = "avg"
		case weightedAverage = "wavg"
	}

	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}
}
