import Foundation

public struct UserWorkoutResultTurbo: Searchable {

	public var productName: String? // ie file_id.product_name --> SPECIALIZED_WSBC601160149N
	public var averageMotorPower: Int?
	public var maximumMotorPower: Int?
	public var minimumMotorTemperature: Int?
	public var averageMotorTemperature: Int?
	public var maximumMotorTemperature: Int?
	public var minimumBattery1: Int?
	public var averageBattery1: Int?
	public var maximumBattery1: Int?
	public var minimumBattery2: Int?
	public var averageBattery2: Int?
	public var maximumBattery2: Int?
	public var minimumProfileScale: Int?
	public var averageProfileScale: Int?
	public var maximumProfileScale: Int?
	public var minimumCurrentScale: Int?
	public var averageCurrentScale: Int?
	public var maximumCurrentScale: Int?
	public var averageSupportFactor: Double?
	public var maximumSupportFactor: Double?
	public var minimumBatteryWh1: Int?
	public var averageBatteryWh1: Int?
	public var maximumBatteryWh1: Int?
	public var minimumBatteryWh2: Int?
	public var averageBatteryWh2: Int?
	public var maximumBatteryWh2: Int?
	public var assistChanges: Int?
	public var minimumAssist: Int?
	public var averageAssist: Int?
	public var maximumAssist: Int?
	public var timeInAssist0P: Double?
	public var timeInAssist1P: Double?
	public var timeInAssist2P: Double?
	public var timeInAssist3P: Double?
	public var timeInAssist4P: Double?
	public var timeInAssist5P: Double?
	public var timeInAssist6P: Double?
	public var bat1DecayAssist0P: Int?
	public var bat1DecayAssist1P: Int?
	public var bat1DecayAssist2P: Int?
	public var bat1DecayAssist3P: Int?
	public var bat1DecayAssist4P: Int?
	public var bat1DecayAssist5P: Int?
	//public var bat1DecayAssist6P: Int?
	public var bat2DecayAssist0P: Int? // off
	public var bat2DecayAssist1P: Int? // eco
	public var bat2DecayAssist2P: Int? // sport/trail
	public var bat2DecayAssist3P: Int? // turbo
	public var bat2DecayAssist4P: Int? // smart
	public var bat2DecayAssist5P: Int?
	//public var bat2DecayAssist6P: Int?


	public init() {}

	// MARK: Codable

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case productName = "product"
		case averageMotorPower = "avgMotorPower"
		case maximumMotorPower = "maxMotorPower"
		case minimumMotorTemperature = "minMotorTemp"
		case averageMotorTemperature = "avgMotorTemp"
		case maximumMotorTemperature = "maxMotorTemp"
		case minimumBattery1 = "minBattery1"
		case averageBattery1 = "avgBattery1"
		case maximumBattery1 = "maxBattery1"
		case minimumBattery2 = "minBattery2"
		case averageBattery2 = "avgBattery2"
		case maximumBattery2 = "maxBattery2"
		case minimumProfileScale = "minProfileScale"
		case averageProfileScale = "avgProfileScale"
		case maximumProfileScale = "maxProfileScale"
		case minimumCurrentScale = "minCurrentScale"
		case averageCurrentScale = "avgCurrentScale"
		case maximumCurrentScale = "maxCurrentScale"
		case averageSupportFactor = "avgSupportFactor"
		case maximumSupportFactor = "maxSupportFactor"
		case minimumBatteryWh1 = "minBatteryWh1"
		case averageBatteryWh1 = "avgBatteryWh1"
		case maximumBatteryWh1 = "maxBatteryWh1"
		case minimumBatteryWh2 = "minBatteryWh2"
		case averageBatteryWh2 = "avgBatteryWh2"
		case maximumBatteryWh2 = "maxBatteryWh2"
		case assistChanges = "numAssistChanges"
		case minimumAssist = "minAssist"
		case averageAssist = "avgAssist"
		case maximumAssist = "maxAssist"
		case timeInAssist0P
		case timeInAssist1P
		case timeInAssist2P
		case timeInAssist3P
		case timeInAssist4P
		case timeInAssist5P
		case timeInAssist6P
		case bat1DecayAssist0P
		case bat1DecayAssist1P
		case bat1DecayAssist2P
		case bat1DecayAssist3P
		case bat1DecayAssist4P
		case bat1DecayAssist5P
		//case bat1DecayAssist6P
		case bat2DecayAssist0P
		case bat2DecayAssist1P
		case bat2DecayAssist2P
		case bat2DecayAssist3P
		case bat2DecayAssist4P
		case bat2DecayAssist5P
		//case bat2DecayAssist6P
	}
	
	public static func fields(_ fields: [CodingKeys] = CodingKeys.allCases, prefix: String? = nil) -> [String] {
		mapFieldsToSearchStrings(fields: fields, prefix: prefix)
	}

}
