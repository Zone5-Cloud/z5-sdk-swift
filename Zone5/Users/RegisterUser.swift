//
//  RegisterUser.swift
//  Zone5
//
//  Created by Jean Hall on 27/2/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

public struct RegisterUser: Codable, JSONEncodedBody {
	/// Required - A unique email address
	public var email: String?

	/// Required - can not be null or empty
	public var firstname: String?

	/// Required - can not be null or empty
	public var lastname: String?

	/// Optional - phone number
	public var tn: String?

	/// Optional - date of birth - UTC timestamp
	public var dob: Int?

	/// Optional - A Java Locale ID - defaults to current locale
	public var locale: String? = Locale.current.identifier

	/// Optional - A Java TimeZone ID
	public var timezone: String?

	/// Required - can not be null or emptu
	public var password: String?

	/// Optional - If the user has been invited, this is the invite UUID
	public var delegate: String?

	/// Optional - Company ID you wish to join
	public var companyId: Int?

	/// Optional - Coach ID you wish to associate with
	public var coachId: Int?

	/// Optional - Units of measurement
	public var units: UnitMeasurement?
	
	/// Optional - The athlete's threshold power for by sport
	public var pwr: [ActivityType: UserThresholdPower]?

	/// Optional - The athlete's threshold heart rate and max heart rate by sport
	public var bpm: [ActivityType: UserThresholdHeart]?

	/// Optional - The athlete's threshold pace by sport
	public var pace: [ActivityType: UserThresholdPace]?
		
	/// Optional - The athlete's current weight (kg)
	public var weight: Double?

	/// Optional - Use this to request association with a specific company based on the company nic
	public var tags: String?
	
	var accept: [String]?
	
	var billingCountry: String?

	/// Optional - Custom registration directives
	public var params: [String: String]?
	
	public init() { }
	public init(email: String, password: String, firstname: String, lastname: String, accept: [String]? = nil, billingCountry: String? = nil) {
		self.email = email
		self.password = password
		self.firstname = firstname
		self.lastname = lastname
		self.accept = accept
		self.billingCountry = billingCountry
	}
}
