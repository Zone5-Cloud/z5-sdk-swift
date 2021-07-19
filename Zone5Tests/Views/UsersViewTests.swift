//
//  UsersViewTests.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 7/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class UsersViewTests: XCTestCase {

	func testMe() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<User, Zone5.Error>)] = [
			(
				token: nil,
				json: "{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					return user
				}
			),
		]

		execute(with: tests) { client, _, urlSession, test in

			client.users.me { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)

				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.id, rhs.id)
					XCTAssertEqual(lhs.uuid, rhs.uuid)
					XCTAssertEqual(lhs.email, rhs.email)
					XCTAssertEqual(lhs.firstName, rhs.firstName)
					XCTAssertEqual(lhs.lastName, rhs.lastName)
					XCTAssertEqual(lhs.avatar, rhs.avatar)

				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testLogin() {
		var serverMessage = Zone5.Error.ServerMessage(message: "this is an error", statusCode: 401)
		serverMessage.errors = [Zone5.Error.ServerMessage.ServerError(field: "a field", message: "a message", code: 111)]
		
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, accept: [String]?, json: String, expectedResult: Result<LoginResponse, Zone5.Error>)] = [
			(
				// this test is for a host that requires client and secret, which is not set, so this should fail
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				accept: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .failure(.invalidConfiguration)
			),
			(
				// simulate a server error
				token: nil,
				host: "http://google.com",
				clientId: "FAIL",
				secret: "FAIL",
				accept: nil,
				json: "{\"message\": \"this is an error\", \"statusCode\": 401, \"errors\": [{\"field\": \"a field\", \"code\":111, \"message\":\"a message\"}]}",
				expectedResult: .failure(.serverError(serverMessage))
			),
			(
				// this test is for a host that does NOT require client and secret, which is not set, and should pass without them
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				accept: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					var lr = LoginResponse()
					lr.user = user
					lr.token = "1234567890"
					return lr
				}
			),
			(
				// this test is the same as above but includes accept strings
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				accept: ["id1", "id2"],
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					var lr = LoginResponse()
					lr.user = user
					lr.token = "1234567890"
					return lr
				}
			),
			(
				// this test is for a host that requires client and secret, and it is provided, so should succeed.
				// also, sticking in a bogus AccessToken which should get overwritten
				token: OAuthToken(rawValue: UUID().uuidString),
				host: "http://google.com",
				clientId: "CLIENT",
				secret: "SECRET",
				accept: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					var lr = LoginResponse()
					lr.user = user
					lr.token = "1234567890"
					return lr
				}
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.login.rawValue)
				if test.clientId == "FAIL" {
					return .failure(test.json, statusCode: 401)
				}
				
				return .success(test.json)
			}

			client.users.login(email: "jane.smith@example.com", password: "pword", clientID: test.clientId, clientSecret: test.secret, accept: test.accept) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertNil(client.accessToken)
					
					if case let Zone5.Error.serverError(message1) = lhs, case let Zone5.Error.serverError(message2) = rhs {
						XCTAssertEqual(message1, message2)
						XCTAssertEqual(message1.error, message2.error)
						XCTAssertEqual(message1.statusCode, message2.statusCode)
						XCTAssertEqual(message1.reason, message2.reason)
						XCTAssertEqual(message1.errors, message2.errors)
					} else if case Zone5.Error.invalidConfiguration = lhs, case Zone5.Error.invalidConfiguration = rhs {
						break;
					} else {
						XCTFail()
					}
					
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.user!.id, rhs.user!.id)
					XCTAssertEqual(lhs.user!.uuid, rhs.user!.uuid)
					XCTAssertEqual(lhs.user!.email, rhs.user!.email)
					XCTAssertEqual(lhs.user!.firstName, rhs.user!.firstName)
					XCTAssertEqual(lhs.user!.lastName, rhs.user!.lastName)
					XCTAssertEqual(lhs.user!.avatar, rhs.user!.avatar)
					XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testLogout() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// logout requires a token, so this will fail authentication
				token: nil,
				json: "true",
				expectedResult: .failure(authFailure)
			),
			(
				// token set. Let's give false from server
				token: OAuthToken(rawValue: "1234567890"),
				json: "false",
				expectedResult: .success(false)
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				json: "true",
				expectedResult: .success(true)
			)
		]

		execute(with: tests) { client, _, urlSession, test in

			client.users.logout { result in
				// token should always be cleared, regardless of outcome
				XCTAssertNil(client.accessToken)
				
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs);
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testDelete() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Zone5.VoidReply, Zone5.Error>)] = [
			(
				// delete requires a token, so this will fail authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				json: "true", // this should fail json decode
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				json: "",
				expectedResult: .success(Zone5.VoidReply())
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.deleteAccount(userID: 123) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testRegister() {
		// register is marked as requires auth, which from the client side just means add the auth header if we have it
		// we let the server side return auth failure or otherwise. The real server will actaully let register
		// through without a token, but the behaviour is different to when a token is attached.
		// As our tests are mocking server responses we are returning an auth failure whenever a token is not added when a token is allowed.
		// so in this test case, the token: nil is simulating a server error, which would happen if the token passed was invalid.
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<User, Zone5.Error>)] = [
			(
				token: nil,
				json: "{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(rawValue: "123"),
				json: "{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					return user
				}
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			var newUser = RegisterUser()
			newUser.email = "jame.smith@example.com"
			newUser.firstname = "Jane"
			newUser.units = UnitMeasurement.imperial
			
			client.users.register(user: newUser) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.id, rhs.id)
					XCTAssertEqual(lhs.uuid, rhs.uuid)
					XCTAssertEqual(lhs.email, rhs.email)
					XCTAssertEqual(lhs.firstName, rhs.firstName)
					XCTAssertEqual(lhs.lastName, rhs.lastName)
					XCTAssertEqual(lhs.avatar, rhs.avatar)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testExists() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test exists does not require authentication
				token: nil,
				json: "true",
				expectedResult: .success(true)
			),
			(
				// test exists does not require authentication, token will get ignored
				token: OAuthToken(rawValue: "123"),
				json: "true",
				expectedResult: .success(true)
			),
			(
				// test exists does not require authentication
				token: nil,
				json: "false",
				expectedResult: .success(false)
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.isEmailRegistered(email: "jame@example") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testResetPassword() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test exists does not require authentication
				token: nil,
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// test exists does not require authentication but can have
				token: OAuthToken(rawValue: "1234567890"),
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// test exists does not require authentication
				token: nil,
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// test exists with invalid json
				token: nil,
				json: "",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.resetPassword(email: "jame@example") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					// token unaffected either way
					XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)
					// token unaffected either way
					XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testChangePassword() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Zone5.VoidReply, Zone5.Error>)] = [
			(
				// changepassword requires a token, so this will fail authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "true",
				expectedResult: .success(Zone5.VoidReply())
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.accessToken = test.token
			
			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testChangePasswordSpecialized() {
		var config = ConfigurationForTesting()
		config.baseURL = URL(string: "https://api-sp-staging.todaysplan.com.au")
		
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Zone5.VoidReply, Zone5.Error>)] = [
			(
				// changepassword requires a token, so this will fail authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "",
				expectedResult: .success {
					return Zone5.VoidReply()
				}
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests, configuration: config) { client, _, urlSession, test in
			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print("change passwordspecialized unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTAssertTrue(false)
				}
			}
		}
	}
	
	func testUpdateUser() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// update user requires a token, so this will fail authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "true",
				expectedResult: .success(true)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "false",
				expectedResult: .success(false)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.updateUser(user: User(email: "test@gmail.com", password: "34123", firstname: "first", lastname: "name")) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	/// Test Gigya refresh, which does not need a refresh token, but does need an auth token in the header
	func testRefreshToken() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<OAuthTokenAlt, Zone5.Error>)] = [
			(
				// this test requires a token, so this should fail
				token: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .failure(authFailure)
			),
			(
				// this test is valid and should pass
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"token\": \"0987654321\", \"tokenExp\": 1234}",
				expectedResult: .success {
					var token = OAuthTokenAlt(rawValue: "0987654321")
					token.tokenExp = 1234
					return token
				}
			),
			(
				// this test should fail decode because compulsory token is not included
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"tokenExp\": 1234}",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.refreshToken { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.tokenExp, rhs.tokenExp)
					XCTAssertEqual(lhs.token, rhs.token)
					XCTAssertEqual(client.accessToken?.rawValue, "0987654321")
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testGetPrefs() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<UsersPreferences, Zone5.Error>)] = [
			(
				// test requires authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// success
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"metric\": \"metric\"}",
				expectedResult: .success {
					var prefs = UsersPreferences()
					prefs.metric = .metric
					return prefs
				}
			),
			(
				// success
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"metric\": \"imperial\"}",
				expectedResult: .success {
					var prefs = UsersPreferences()
					prefs.metric = .imperial
					return prefs
				}
			),
			(
				// invalid json
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.users.getPreferences(userID: 123) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.metric, rhs.metric)
					XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testSetPrefs() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test requires authentication
				token: nil,
				json: "",
				expectedResult: .failure(authFailure)
			),
			(
				// success
				token: OAuthToken(rawValue: "1234567890"),
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// false from server
				token: OAuthToken(rawValue: "1234567890"),
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// invalid json
				token: OAuthToken(rawValue: "1234567890"),
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			 
			var prefs = UsersPreferences()
			prefs.metric = .metric
			client.users.setPreferences(preferences: prefs) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)
					XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
				default:
					print("unexpected response: \(result)", "expected: \(test.expectedResult)")
					XCTFail()
				}
			}
		}
	}
	
	func testPasswordComplexity() {
		let expected = #"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$"#
		let tests: [(token: AccessToken?,json: String, expectedResult: Result<String, Zone5.Error>)] = [
			(token: OAuthToken(rawValue: "1234567890"), json: expected, expectedResult: .success(expected))
		]
		execute(with: tests) { client, _, urlSession, test in

			client.users.passwordComplexity() { result in
				switch result {
				case .success(let regex):
					XCTAssertEqual(regex, test.json)
					
				default:
					XCTFail()
				}
			}
		}
	}
	
	func testReconfirm() {
		let tests = [""]
		execute(with: tests) { client, _, urlSession, expected in
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/reconfirm")
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
				XCTAssertEqual(request.url?.query, "email=test%2Bplus@gmail.com")

				return .success("")
			}

			client.users.reconfirmEmail(email: "test+plus@gmail.com") { result in
				switch result {
				case .success(_):
					XCTAssertTrue(true)
				default:
					XCTFail()
				}
			}
		}
	}
}
