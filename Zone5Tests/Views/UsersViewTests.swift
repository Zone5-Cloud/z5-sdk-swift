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
				token: OAuthToken(token: UUID().uuidString, refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
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

        let assertionsOnSuccess: Zone5.Result<User>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.id, rhs.id)
            XCTAssertEqual(lhs.uuid, rhs.uuid)
            XCTAssertEqual(lhs.email, rhs.email)
            XCTAssertEqual(lhs.firstName, rhs.firstName)
            XCTAssertEqual(lhs.lastName, rhs.lastName)
            XCTAssertEqual(lhs.avatar, rhs.avatar)
        }

        var expectations: [XCTestExpectation] = []
        execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            client.users.me(completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
	
	func testLogin() {
		var serverMessage = Zone5.Error.ServerMessage(message: "this is an error", statusCode: 401)
		serverMessage.errors = [Zone5.Error.ServerMessage.ServerError(field: "a field", message: "a message", code: 111)]
		
		let tests: [(token: AccessToken?, host: String, clientId: String?, secret: String?, accept: [String]?, json: String, expectedResult: Result<LoginResponse, Zone5.Error>)] = [
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
				// this test has should pass, it also includes accept strings
				token: nil,
				host: "http://\(Zone5.specializedStagingServer)",
				clientId: "CLIENT",
				secret: nil,
				accept: ["id1", "id2"],
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\", \"updatedTerms\":[{\"id\":\"terms123\"}]}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					var lr = LoginResponse()
					lr.user = user
					lr.token = "1234567890"
					var t = UpdatedTerms()
					t.id = "terms123"
					lr.updatedTerms = [t]
					return lr
				}
			),
			(
				// this test should pass.
				// also, sticking in a bogus AccessToken which should get overwritten
				token: OAuthToken(token: UUID().uuidString, refresh: "refreshtoken", tokenExp: 300000000, username: "testuser"),
				host: "http://google.com",
				clientId: "CLIENT",
				secret: "SECRET",
				accept: nil,
				json: "{\"user\": {\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}, \"token\": \"1234567890\", \"tokenExp\": 1631074590000, \"features\": 0, \"identities\": { \"COGNITO\": \"123\", \"GIGYA\": \"456\"},\"roles\": [\"user\", \"premium\"], \"refresh\": \"eyJjd\", \"fs\":\"specialized\"}",
				expectedResult: .success {
					var user = User()
					user.id = 12345678
					user.email = "jame.smith@example.com"
					user.firstName = "Jane"
					user.lastName = "Smith"
					var lr = LoginResponse()
					lr.user = user
					lr.token = "1234567890"
					lr.refresh = "eyJjd"
					lr.features = 0
					lr.fs = "specialized"
					lr.tokenExp = 1631074590000
					lr.roles = [Roles.user, Roles.premium]
					lr.identities = ["COGNITO":"123","GIGYA":"456"]
					return lr
				}
			)
		]

        let assertionsOnSuccess: Zone5.Result<LoginResponse>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.user!.id, rhs.user!.id)
            XCTAssertEqual(lhs.user!.uuid, rhs.user!.uuid)
            XCTAssertEqual(lhs.user!.email, rhs.user!.email)
            XCTAssertEqual(lhs.user!.firstName, rhs.user!.firstName)
            XCTAssertEqual(lhs.user!.lastName, rhs.user!.lastName)
            XCTAssertEqual(lhs.user!.avatar, rhs.user!.avatar)
        }

        var expectations: [XCTestExpectation] = []
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

            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

			client.clientID = test.clientId
			client.clientSecret = test.secret
            client.users.login(email: "jane.smith@example.com", password: "pword", clientID: test.clientId, clientSecret: test.secret, accept: test.accept) { result in
                if case .failure = result, case .failure = test.expectedResult {
                    XCTAssertNil(client.accessToken)
                }
                else if case .success = result, case .success = test.expectedResult {
                    XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
					XCTAssertEqual(try? result.get().token, try? test.expectedResult.get().token)
					XCTAssertEqual(try? result.get().refresh, try? test.expectedResult.get().refresh)
					XCTAssertEqual(try? result.get().tokenExp, try? test.expectedResult.get().tokenExp)
					XCTAssertEqual(try? result.get().roles, try? test.expectedResult.get().roles)
					XCTAssertEqual(try? result.get().identities, try? test.expectedResult.get().identities)
					XCTAssertEqual(try? result.get().fs, try? test.expectedResult.get().fs)
					XCTAssertEqual(try? result.get().features, try? test.expectedResult.get().features)
					XCTAssertEqual(try? result.get().updatedTerms?.count, try? test.expectedResult.get().updatedTerms?.count)
					XCTAssertEqual(try? result.get().updatedTerms?[0].id, try? test.expectedResult.get().updatedTerms?[0].id)
                }

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "false",
				expectedResult: .success(false)
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "true",
				expectedResult: .success(true)
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            client.users.logout { result in
				// token should always be cleared, regardless of outcome
				XCTAssertNil(client.accessToken)

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "true", // this should fail json decode
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			),
			(
				// token set. Let's give true from server
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "",
				expectedResult: .success(Zone5.VoidReply())
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

			client.users.deleteAccount(userID: 123) { result in
                if case .success = result, case .success = test.expectedResult {
                    XCTAssertEqual(client.accessToken?.rawValue,  test.token?.rawValue)
                }

                expectation.fulfill(with: result)
            }
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "123", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
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

        let assertionsOnSuccess: Zone5.Result<User>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.id, rhs.id)
            XCTAssertEqual(lhs.uuid, rhs.uuid)
            XCTAssertEqual(lhs.email, rhs.email)
            XCTAssertEqual(lhs.firstName, rhs.firstName)
            XCTAssertEqual(lhs.lastName, rhs.lastName)
            XCTAssertEqual(lhs.avatar, rhs.avatar)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			var newUser = RegisterUser()
			newUser.email = "jame.smith@example.com"
			newUser.firstname = "Jane"
			newUser.units = UnitMeasurement.imperial
			newUser.accept = ["termsid", "terms2id"]

            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            client.users.register(user: newUser, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "123", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
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

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            client.users.isEmailRegistered(email: "jame@example", completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
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

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

			client.users.resetPassword(email: "jame@example") { result in
                // token unaffected either way
                XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "",
				expectedResult: .success(Zone5.VoidReply())
			),
			(
				// token set.
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			client.accessToken = test.token

            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
                // token unaffected either way
                XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
	}
	
	func testTestPassword() {
		let expectation = self.expectation(description: "request returned")
		
		execute(with: ["{\"error\":true,\"message\":\"This password can not be used. It does not meet the complexity requirements\",\"reason\":\"complexity\"}"]) { z5, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/test-password")
				
				return .success(test)
			}
			
			z5.users.testPassword(username: "user@gmail.com", password: "password") { result in
				if case .success(let msg) = result {
					XCTAssertNotNil(msg.error)
					XCTAssertNotNil(msg.message)
					XCTAssertNotNil(msg.reason)
				} else {
					XCTAssert(false, "unexpected failure")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testTestPasswordNoError() {
		let expectation = self.expectation(description: "request returned")
		
		execute(with: ["{\"error\":false}"]) { z5, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/test-password")
				
				return .success(test)
			}
			
			z5.users.testPassword(username: "user@gmail.com", password: "password") { result in
				if case .success(let msg) = result {
					XCTAssertNotNil(msg.error)
					XCTAssertNil(msg.message)
					XCTAssertNil(msg.reason)
				} else {
					XCTAssert(false, "unexpected failure")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "",
				expectedResult: .success {
					return Zone5.VoidReply()
				}
			),
			(
				// token set.
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests, configuration: config) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

			client.users.changePassword(oldPassword: "old", newPassword: "new") { result in
                // token unaffected either way
                XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "true",
				expectedResult: .success(true)
			),
			(
				// token set.
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "false",
				expectedResult: .success(false)
			),
			(
				// token set.
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "should fail decode",
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

			client.users.updateUser(user: User(email: "test@gmail.com", password: "34123", firstname: "first", lastname: "name")) { result in
                // token unaffected either way
                XCTAssertEqual(client.accessToken?.rawValue, test.token?.rawValue)

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "{\"metric\": \"metric\"}",
				expectedResult: .success {
					var prefs = UsersPreferences()
					prefs.metric = .metric
					return prefs
				}
			),
			(
				// success
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "{\"metric\": \"imperial\"}",
				expectedResult: .success {
					var prefs = UsersPreferences()
					prefs.metric = .imperial
					return prefs
				}
			),
			(
				// invalid json
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        let assertionsOnSuccess: Zone5.Result<UsersPreferences>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.metric, rhs.metric)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

			client.users.getPreferences(userID: 123) { result in
                if case .success = result, case .success = test.expectedResult {
                    XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
                }

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
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
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "true",
				expectedResult: .success {
					return true
				}
			),
			(
				// false from server
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "false",
				expectedResult: .success {
					return false
				}
			),
			(
				// invalid json
				token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"),
				json: "{\"metric\": \"imperiall\"}", // type should fail deserialisation
				expectedResult: .failure(Zone5.Error.failedDecodingResponse(Zone5.Error.unknown))
			)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			var prefs = UsersPreferences()
			prefs.metric = .metric

            let expectation = ResultExpectation(for: test.expectedResult)
            expectations.append(expectation)

            client.users.setPreferences(preferences: prefs) { result in
                if case .success = result, case .success = test.expectedResult {
                    XCTAssertEqual(client.accessToken?.rawValue, "1234567890")
                }

                expectation.fulfill(with: result)
			}
		}

        wait(for: expectations, timeout: 5)
	}
	
	func testPasswordComplexity() {
		let expected = #"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$"#
		let tests: [(token: AccessToken?,json: String, expectedResult: Result<String, Zone5.Error>)] = [
			(token: OAuthToken(token: "1234567890", refresh: "resfresh", tokenExp: 3000000, username: "testuser"), json: expected, expectedResult: .success(expected))
		]

        let assertionsOnSuccess: Zone5.Result<String>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs, rhs)
        }

        var expectations: [XCTestExpectation] = []
        execute(with: tests) { client, _, urlSession, test in
            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            client.users.passwordComplexity(completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
	
	func testReconfirm() {
        let tests: [Result<Zone5.VoidReply, Zone5.Error>] = [
            .success(Zone5.VoidReply()),
        ]

        var expectations: [XCTestExpectation] = []
        execute(with: tests) { client, _, urlSession, expectedResult in
            urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/reconfirm")
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
				XCTAssertEqual(request.url?.query, "email=test%2Bplus@gmail.com")

				return .success("")
			}

            let expectation = ResultExpectation(for: expectedResult)
            expectations.append(expectation)

            client.users.reconfirmEmail(email: "test+plus@gmail.com", completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
}
