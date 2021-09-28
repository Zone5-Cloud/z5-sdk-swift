//
//  LoginResponseTests.swift
//  Zone5Tests
//
//  Created by Jean Hall on 28/9/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class LoginResponseTests: XCTestCase {

	func testDecodeUnknownRole() throws {
		let response = "{\"hasFriends\":false,\"roles\":[\"user\",\"premium\",\"beta2\",\"pi\",\"stageslink\",\"beta3\",\"unknownRole\"],\"token\":\"123\"}".data(using: .utf8)!
		let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: response)
		XCTAssertEqual(loginResponse.token, "123")
		XCTAssertNotNil(loginResponse.roles)
		XCTAssertTrue([.beta2, .beta3, .pi, .stageslink, .user, .premium, .unknown].allSatisfy({loginResponse.roles!.contains($0)}))
	}
	
    func testDecode() throws {
		// this is a copy of a response received from the server with a legacy token that had unexpected structure
		let response = "{\"hasFriends\":false,\"roles\":[\"user\",\"premium\",\"beta2\",\"pi\",\"stageslink\",\"beta3\"],\"branding\":{\"id\":1,\"cls\":\"company\",\"nic\":\"staging\",\"name\":\"Today's Plan\",\"colour1\":\"\",\"colour2\":\"#eb1a44\",\"isCoach\":false,\"isPromotor\":true,\"isTeam\":false,\"isManufacturer\":false,\"emailTemplateId\":\"abec3010-4ed5-4186-9c7f-5bdc0d14e7ea\",\"fromUser\":\"Today's Plan\"},\"delegateTally\":{\"total\":0},\"hasRelationship\":false,\"services\":{\"subscriptions\":[{\"startDate\":1515029126022,\"trialEndDate\":1515633926022,\"dueDate\":1641259526022,\"daysRemaining\":97,\"autoRenew\":true,\"definitionId\":6394474,\"instanceId\":7279643,\"name\":\"System training plans + tools and analytics - yearly\",\"cost\":199.0,\"currency\":\"usd\",\"tax\":\"none\",\"cancelAtPeriodEnd\":false,\"user\":{\"id\":7195586,\"firstname\":\"jean\",\"lastname\":\"hall\"},\"company\":{\"id\":4,\"cls\":\"company\",\"name\":\"Stages Cycling\"},\"type\":\"plan\",\"interval\":\"year\"},{\"startDate\":1515029126022,\"trialEndDate\":1515633926022,\"dueDate\":1641259526022,\"daysRemaining\":97,\"autoRenew\":true,\"definitionId\":6394474,\"instanceId\":7279643,\"name\":\"System training plans + tools and analytics - yearly\",\"cost\":199.0,\"currency\":\"usd\",\"tax\":\"none\",\"cancelAtPeriodEnd\":false,\"user\":{\"id\":7195586,\"firstname\":\"jean\",\"lastname\":\"hall\"},\"company\":{\"id\":4,\"cls\":\"company\",\"name\":\"Stages Cycling\"},\"type\":\"plan\",\"interval\":\"year\"},{\"startDate\":1515029126022,\"trialEndDate\":1515633926022,\"dueDate\":1641259526022,\"daysRemaining\":97,\"autoRenew\":true,\"definitionId\":6394474,\"instanceId\":7279643,\"name\":\"System training plans + tools and analytics - yearly\",\"cost\":199.0,\"currency\":\"usd\",\"tax\":\"none\",\"cancelAtPeriodEnd\":false,\"user\":{\"id\":7195586,\"firstname\":\"jean\",\"lastname\":\"hall\"},\"company\":{\"id\":4,\"cls\":\"company\",\"name\":\"Stages Cycling\"},\"type\":\"plan\",\"interval\":\"year\"},{\"startDate\":1515029126022,\"trialEndDate\":1515633926022,\"dueDate\":1641259526022,\"daysRemaining\":97,\"autoRenew\":true,\"definitionId\":6394474,\"instanceId\":7279643,\"name\":\"System training plans + tools and analytics - yearly\",\"cost\":199.0,\"currency\":\"usd\",\"tax\":\"none\",\"cancelAtPeriodEnd\":false,\"user\":{\"id\":7195586,\"firstname\":\"jean\",\"lastname\":\"hall\"},\"company\":{\"id\":4,\"cls\":\"company\",\"name\":\"Stages Cycling\"},\"type\":\"plan\",\"interval\":\"year\"}],\"plans\":[]},\"fs\":\"general\",\"token\":\"12345\",\"tokenExp\":1635387343487,\"features\":0,\"companies\":[],\"identities\":[\"COGNITO\"],\"canswitch\":true,\"primaryCompanyId\":1,\"user\":{\"id\":7195586,\"email\":\"jean@todaysplan.com.au\",\"md5\":\"de00426a40a7311820308cd3be136455\",\"cid\":\"4fdda155-d962-4290-962d-6b3cd89f483e\",\"firstname\":\"jean\",\"lastname\":\"hall\",\"locale\":\"en_US\",\"timezone\":\"Australia/Sydney\",\"formatTime\":\"h:mm a\",\"formatDate\":\"M/d/yy\",\"weekStart\":\"mon\",\"displayName\":\"first\",\"tags\":\"stageslink\",\"lat\":-35.25428934954107,\"lon\":149.05898161232471,\"premiumExpiryTs\":1641259526022,\"isPremium\":true,\"hasPwr\":true,\"hasBpm\":true,\"createdTime\":1499815973350,\"metric\":\"metric\",\"hasFiles\":true,\"hasPlanBuilder\":true,\"hasWorkoutBuilder\":true,\"latestFileTs\":1630550541000,\"powermeterManufacturers\":\"7,263,1,9,51,69,29,63\",\"billingCountry\":\"US\",\"lastLogin\":1632795343517,\"company\":{\"id\":1,\"cls\":\"company\",\"nic\":\"staging\"},\"systemNoticeId\":0,\"schedulePref\":\"prefer_single\",\"equipment\":[\"road\"],\"roles\":[\"beta2\",\"beta3\",\"pi\",\"stageslink\",\"user\",\"premium\"],\"attsMask\":8129535,\"prefsMask\":1,\"sportsMask\":19,\"hasPlanService\":true,\"coachPrefsMask\":0}}".data(using: .utf8)!
		
		let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: response)
		XCTAssertNotNil(loginResponse)
		XCTAssertEqual(loginResponse.token, "12345")
		XCTAssertEqual(loginResponse.tokenExp, 1635387343487)
		XCTAssertTrue([.beta2, .beta3, .pi, .stageslink, .user, .premium].allSatisfy({loginResponse.roles!.contains($0)}))
		XCTAssertEqual(loginResponse.companies, [])
		
		XCTAssertNil(loginResponse.refresh)
		XCTAssertNil(loginResponse.expiresIn)
		
		XCTAssertNotNil(loginResponse.user)
    }


}
