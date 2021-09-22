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

	func testPairThirdParty() {
		let tests: [(type: UserConnectionType, redirect: URL, expectedResult: Zone5.Result<String>)] = [
			(type: .wahoo, redirect: URL(string: "https://redirect.com")!, expectedResult: .success("https://thisisaurl.com")),
			(type: .strava, redirect: URL(string: "nativeapp://native.com")!, expectedResult: .success("https://connect.specialized.com"))
		]
		
		var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/connections/service/\(test.type.connectionName)")
				return .success((try? test.expectedResult.get()) ?? "")
			}

			let expectation = ResultExpectation(for: test.expectedResult)
			expectations.append(expectation)

			_ = client.thirdPartyConnections.pairThirdPartyConnection(type: test.type, redirect: test.redirect, completion: expectation.fulfill)
		}

		wait(for: expectations, timeout: 5)
	}
	
    func testSetThirdPartyToken() {
		var tests: [(type: UserConnectionType, parameters: URLEncodedBody, expectedResult: Zone5.Result<Zone5.VoidReply>)] = []
		
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

        var expectations: [XCTestExpectation] = []
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

            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            _ = client.thirdPartyConnections.setThirdPartyToken(type: test.type, parameters: test.parameters, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
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
		
        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/connections")

                switch test.json {
                case "{}":
                    return .failure("Unauthorized", statusCode: 401)

                default:
                    return .success(test.json)
                }
			}

            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            _ = client.thirdPartyConnections.hasThirdPartyToken(type: test.type, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
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

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/connections/rem/strava")

                switch test.json {
                case "{}":
                    return .failure("Unauthorized", statusCode: 401)

                default:
                    return .success(test.json)
                }
			}

            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            _ = client.thirdPartyConnections.removeThirdPartyToken(type: UserConnectionType.strava, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

    func testRegisterDeviceWithThirdParty() {
        let tests: [(token: AccessToken?, json: String, expectedResult: Zone5.Result<PushRegistrationResponse>)] = [
			(
				// endpoint requires auth
				token: nil,
				json: "{\"token\": 12345}",
				expectedResult: .failure(authFailure)
			),
			(
				// success
				token: OAuthToken(token: UUID().uuidString, refresh: "refresh", tokenExp: 30000, username: "testuser"),
				json: "{\"token\": 12345}",
				expectedResult: .success {
					return PushRegistrationResponse(token: 12345)
				}
			),
			(
				// invalid response
				token: OAuthToken(token: UUID().uuidString, refresh: "refresh", tokenExp: 30000, username: "testuser"),
				json: "{\"success\": true}",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        let assertionsOnSuccess: Zone5.Result<PushRegistrationResponse>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.token, rhs.token)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            _ = client.thirdPartyConnections.registerDeviceWithThirdParty(registration: pushRegistration1, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

    func testDeregisterDeviceWithThirdParty() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Zone5.Result<Zone5.VoidReply>)] = [
			(
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(token: UUID().uuidString, refresh: "refresh", tokenExp: 30000, username: "testuser"),
				json: "",
				expectedResult: .success(Zone5.VoidReply())
			),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            _ = client.thirdPartyConnections.deregisterDeviceWithThirdParty(token: "12345", completion: expectation.fulfill)
        }

        wait(for: expectations, timeout: 5)
	}

	func testGetDeprecated() {
        let tests: [(token: AccessToken?, json: String, expectedResult: Zone5.Result<UpgradeAvailableResponse>)] = [
			(
				token: nil,
				json: "{}",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(token: UUID().uuidString, refresh: "refresh", tokenExp: 30000, username: "testuser"),
				json: "{\"upgrade\": true}",  //TODO: Find out what the tag/result really is
				expectedResult: .success {
					return UpgradeAvailableResponse(isUpgradeAvailable: true)
				}
			),
		]

        let assertionsOnSuccess: Zone5.Result<UpgradeAvailableResponse>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.isUpgradeAvailable, rhs.isUpgradeAvailable)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            _ = client.userAgents.getDeprecated(completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
}
