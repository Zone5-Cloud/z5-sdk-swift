//
//  UserConnectionType.swift
//  Zone5
//
//  Created by Daniel Farrelly on 11/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

public enum UserConnectionType: Int, Codable, CaseIterable {

	case garminconnect = 0
	
	case fitbit = 1
	
	case withings = 2

	case myfitnesspal = 3
	
	case underarmour = 4
	
	case garminwellness = 5
	
	case trainingpeaks = 6
	
	case strava = 7
	
	case polar = 8
	
	case ridewithgps = 9
	
	case todaysplan = 10
	
	case suunto = 11
	
	case garmintraining = 12
	
	case turbo = 13
	
	// Specialized Ride
	case specialized = 14
	
	case nike = 15
	
	case wahoo = 16
	
	var connectionName: String {
		switch self {
		case .garminconnect: return "garminconnect"
		case .fitbit: return "fitbit"
		case .withings: return "withings"
		case .myfitnesspal: return "myfitnesspal"
		case .underarmour: return "underarmour"
		case .garminwellness: return "garminwellness"
		case .trainingpeaks: return "trainingpeaks"
		case .strava: return "strava"
		case .polar: return "polar"
		case .ridewithgps: return "ridewithgps"
		case .todaysplan: return "todaysplan"
		case .suunto: return "suunto"
		case .garmintraining: return "garmintraining"
		case .turbo: return "turbo"
		case .specialized: return "specialized"
		case .nike: return "nike"
		case .wahoo: return "wahoo"
		}
	}
}
