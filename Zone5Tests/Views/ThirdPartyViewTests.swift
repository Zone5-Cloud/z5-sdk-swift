//
//  ThirdPartyViewTests.swift
//  Zone5
//
//  Created by John Covele on Oct 16, 2020.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class ThirdPartyViewTests: XCTestCase {
	
	let pushRegistration1 = PushRegistration(token: "12345", platform: "ios", deviceId: "johhny")
	
	func testSetThirdPartyToken() {
		var tests: [(type: UserConnectionType, parameters: URLEncodedBody, expectedResult: Result<Zone5.VoidReply, Zone5.Error>)] = []
		
		for type in UserConnectionType.allCases {
			tests.append((
				type: type,
				parameters: ["oauth_token": "token", "oauth_verifier": "verifier"],
				expectedResult: .success(Zone5.VoidReply())
			))
			tests.append((
				type: type,
				parameters: [],
				expectedResult: .success(Zone5.VoidReply())
			))
		}
		
		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/files/\(test.type.connectionName)/confirm")
				if test.parameters.queryItems.count > 0 {
					XCTAssertEqual(request.url?.query, "\(test.parameters.description)&noredirect=true")
				} else {
					XCTAssertEqual(request.url?.query, "noredirect=true")
				}
				
				return .success("")
			}
			
			let _ = client.thirdPartyConnections.setThirdPartyToken(type: test.type, parameters: test.parameters) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					
				case (.success(let lhs), .success(let rhs)):
					XCTAssertNotNil(lhs)
					XCTAssertNotNil(rhs)
					
				default:
					XCTFail("\(result) != \(test.expectedResult)")
				}
			}
		}
	}
	
	func testHasThirdPartyToken() {
		var tests: [(type: UserConnectionType, json: String, expectedResult: Result<Bool, Zone5.Error>)] = []
		for type in UserConnectionType.allCases {
			tests.append((
				type: type,
				json: "[{\"type\": \"\(type.connectionName)\",\"enabled\": true}]",
				expectedResult: .success(true)
			))
			tests.append((
				type: type,
				json: "[{\"type\": \"\(type.connectionName)\",\"enabled\": false}]",
				expectedResult: .success(false)
			))
			tests.append((
				type: type,
				json: "{}",
				expectedResult: .failure(authFailure)
			))
		}
		
		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/connections")
				return .success(test.json)
			}
			
			let _ = client.thirdPartyConnections.hasThirdPartyToken(type: test.type) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)
					
				default:
					XCTFail("\(result) != \(test.expectedResult)")
				}
			}
		}
	}

	
	func testRemoveThirdPartyToken() {
		let tests: [(json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				json: "{}",
				expectedResult: .failure(authFailure)
			),
			(
				json: "true",
				expectedResult: .success(true)
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/connections/rem/strava")
				return .success(test.json)
			}
			
			let _ = client.thirdPartyConnections.removeThirdPartyToken(type: UserConnectionType.strava) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)

				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)

				default:
					XCTFail("\(result) != \(test.expectedResult)")
				}
			}
		}
	}



	func testRegisterDeviceWithThirdParty() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<PushRegistrationResponse, Zone5.Error>)] = [
			(
				// endpoint requires auth
				token: nil,
				json: "{\"token\": 12345}",
				expectedResult: .failure(authFailure)
			),
			(
				// success
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{\"token\": 12345}",
				expectedResult: .success {
					return PushRegistrationResponse(token: 12345)
				}
			),
			(
				// invalid response
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{\"success\": true}",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			let _ = client.thirdPartyConnections.registerDeviceWithThirdParty(registration: pushRegistration1) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)

				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.token, rhs.token)
	
				default:
					XCTFail("\(result) != \(test.expectedResult)")
				}
			}
		}
	}


	func testDeregisterDeviceWithThirdParty() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Zone5.VoidReply, Zone5.Error>)] = [
			(
				token: nil,
				json: "{}",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{}",
				expectedResult: .success {
					return Zone5.VoidReply()
				}
			),
		]

		execute(with: tests) { client, _, urlSession, test in
			let _ = client.thirdPartyConnections.deregisterDeviceWithThirdParty(token: "12345") { result in
                DispatchQueue.main.async {
                    switch (result, test.expectedResult) {
                    case (.failure(let lhs), .failure(let rhs)):
                        XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
                        XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)

                    //case (.success(let lhs), .success(let rhs)):
                    //XCTAssertEqual(lhs, rhs)  //TODO: how to test for success?

                    default:
                        XCTFail("\(result) != \(test.expectedResult)")
                    }
                }
			}
		}
	}

	func testGetDeprecated() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<UpgradeAvailableResponse, Zone5.Error>)] = [
			(
				token: nil,
				json: "{}",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{\"upgrade\": true}",  //TODO: Find out what the tag/result really is
				expectedResult: .success {
					return UpgradeAvailableResponse(isUpgradeAvailable: true)
				}
			),
		]

		execute(with: tests) { client, _, urlSession, test in

			let _ = client.userAgents.getDeprecated() { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)

				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.isUpgradeAvailable, rhs.isUpgradeAvailable)

				default:
					print(result, test.expectedResult)
					XCTFail("\(result) != \(test.expectedResult)")
				}
			}
		}
	}
}
