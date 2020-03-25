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
				expectedResult: .failure(.requiresAccessToken)
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
			client.accessToken = test.token

			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/users/me")
				XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer \(test.token?.rawValue ?? "UNKNOWN")")

				return .success(test.json)
			}

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
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testLogin() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<LoginResponse, Zone5.Error>)] = [
			(
				// this test is for a host that requires client and secret, which is not set, so this should fail
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .failure(.invalidConfiguration)
			),
			(
				// this test is for a host that does NOT require client and secret, which is not set, and should pass without them
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
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
				return .success(test.json)
			}

			client.users.login(email: "jane.smith@example.com", password: "pword", clientID: test.clientId, clientSecret: test.secret) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertNil(client.accessToken)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.user!.id, rhs.user!.id)
					XCTAssertEqual(lhs.user!.uuid, rhs.user!.uuid)
					XCTAssertEqual(lhs.user!.email, rhs.user!.email)
					XCTAssertEqual(lhs.user!.firstName, rhs.user!.firstName)
					XCTAssertEqual(lhs.user!.lastName, rhs.user!.lastName)
					XCTAssertEqual(lhs.user!.avatar, rhs.user!.avatar)
					XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testLogout() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// logout requires a token, so this will fail authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// token set. Let's give false from server
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .success {
					return true
				}
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.logout.rawValue)
				return .success(test.json)
			}

			client.users.logout { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertNil(client.accessToken)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs);
					XCTAssertEqual(client.accessToken?.rawValue, lhs ? nil : "1234567890")
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testDelete() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<VoidReply, Zone5.Error>)] = [
			(
				// delete requires a token, so this will fail authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "true", // this should fail json decode
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .success {
					return VoidReply()
				}
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				return .success(test.json)
			}

			client.users.deleteAccount(userID: 123) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testRegister() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<User, Zone5.Error>)] = [
			(
				// register does not require authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
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
			(
				// register does not require authentication
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
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
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.registerUser.rawValue)
				return .success(test.json)
			}

			var newUser = RegisterUser()
			newUser.email = "jame.smith@example.com"
			newUser.firstname = "Jane"
			
			client.users.register(user: newUser) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertNil(client.accessToken)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.id, rhs.id)
					XCTAssertEqual(lhs.uuid, rhs.uuid)
					XCTAssertEqual(lhs.email, rhs.email)
					XCTAssertEqual(lhs.firstName, rhs.firstName)
					XCTAssertEqual(lhs.lastName, rhs.lastName)
					XCTAssertEqual(lhs.avatar, rhs.avatar)
					XCTAssertNil(client.accessToken)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testExists() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test exists does not require authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// test exists does not require authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "false",
				expectedResult: .success {
					return false
				}
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.exists.rawValue)
				return .success(test.json)
			}
			
			client.users.isEmailRegistered(email: "jame@example") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertNil(client.accessToken)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs, rhs)
					XCTAssertNil(client.accessToken)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testResetPassword() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test exists does not require authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// test exists does not require authentication but can have
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// test exists does not require authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// test exists with invalid json
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.passwordReset.rawValue)
				return .success(test.json)
			}
			
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
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testChangePassword() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<VoidReply, Zone5.Error>)] = [
			(
				// changepassword requires a token, so this will fail authentication
				token: nil,
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "true",
				expectedResult: .success {
					return VoidReply()
				}
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://google.com",
				clientId: nil,
				secret: nil,
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.setUser.rawValue)
				return .success(test.json)
			}

			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testChangePasswordSpecialized() {
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, json: String, expectedResult: Result<VoidReply, Zone5.Error>)] = [
			(
				// changepassword requires a token, so this will fail authentication
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "",
				expectedResult: .success {
					return VoidReply()
				}
			),
			(
				// token set.
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: nil,
				secret: nil,
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.changePasswordSpecialized.rawValue)
				return .success(test.json)
			}

			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				case (.success(_), .success(_)):
					XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testRefreshToken() {
		let tests: [(token: AccessToken?, host: String, json: String, expectedResult: Result<OAuthTokenAlt, Zone5.Error>)] = [
			(
				// this test requires a token, so this should fail
				token: nil,
				host: "http://google.com",
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\"}",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// this test is valid and should pass
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				json: "{\"token\": \"0987654321\", \"tokenExp\": 1234}",
				expectedResult: .success {
					var token = OAuthTokenAlt(rawValue: "0987654321")
					token.tokenExp = 1234
					return token
				}
			),
			(
				// this test should fail decode because compulsory token is no included
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://google.com",
				json: "{\"tokenExp\": 1234}",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, UsersView.Endpoints.refreshToken.rawValue)
				return .success(test.json)
			}

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
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testGetPrefs() {
		let tests: [(token: AccessToken?, host: String, json: String, expectedResult: Result<UsersPreferences, Zone5.Error>)] = [
			(
				// test requires authentication
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				json: "",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// success
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
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
				host: "http://\(Zone5.specializedStagingServer)",
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
				host: "http://\(Zone5.specializedStagingServer)",
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				return .success(test.json)
			}
			
			client.users.getPreferences(userID: 123) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)
				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.metric, rhs.metric)
					XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
	
	func testSetPrefs() {
		let tests: [(token: AccessToken?, host: String, json: String, expectedResult: Result<Bool, Zone5.Error>)] = [
			(
				// test requires authentication
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				json: "",
				expectedResult: .failure(.requiresAccessToken)
			),
			(
				// success
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// false from server
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// invalid json
				token: OAuthToken(rawValue: "1234567890"),
				host: "http://\(Zone5.specializedStagingServer)",
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

		execute(with: tests) { client, _, urlSession, test in
			client.baseURL = URL(string: test.host)
			client.accessToken = test.token
			
			urlSession.dataTaskHandler = { request in
				return .success(test.json)
			}
			 
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
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
}
