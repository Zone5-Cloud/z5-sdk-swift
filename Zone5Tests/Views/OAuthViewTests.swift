import XCTest
@testable import Zone5

class OAuthViewTests: XCTestCase {

	func testAccessToken() {
		let tests: [(prepareConfiguration: (_ configuration: inout ConfigurationForTesting) -> Void, response: TestHTTPClientURLSession.Result<String>, expectedResult: Zone5.Result<OAuthToken>)] = [
			( // Should complete with .invalidConfiguration when client is not configured correctly.
				prepareConfiguration: { $0.accessToken = nil; $0.clientID = nil; $0.clientSecret = nil },
				response: .message("{\"message\":\"UT010031: Login failed\"}", statusCode: 500),
				expectedResult: .failure(.invalidConfiguration)
			),
			( // Should complete with .serverError(_:) if a message is transmitted.
				prepareConfiguration: { $0.accessToken = nil },
				response: .message("UT010031: Login failed", statusCode: 500),
                expectedResult: .failure(.serverError(Zone5.Error.ServerMessage(message: "UT010031: Login failed", statusCode: 500)))
			),
			( // Should complete with .serverError(_:) if a message is transmitted, even on success.
				prepareConfiguration: { $0.accessToken = nil },
				response: .success("{\"message\":\"UT010031: Login failed\"}"),
				expectedResult: .failure(.serverError(Zone5.Error.ServerMessage(message: "UT010031: Login failed")))
			),
			( // Should complete with .failedDecodingResponse(_:) when an unexpected JSON value is returned.
				prepareConfiguration: { $0.accessToken = nil },
				response: .success("Request should fail for invalid response content (such as something that isn't even JSON)."),
				expectedResult: .failure(.failedDecodingResponse(Zone5.Error.unknown))
			),
			( // Should succeed when a valid response is returned from the server.
				prepareConfiguration: { $0.accessToken = nil },
				response: .success("{\"access_token\":\"ACCESS_TOKEN_VALUE\",\"ignored_value\":\"that is dropped during decoding\"}"),
				expectedResult: .success(OAuthToken(rawValue: "ACCESS_TOKEN_VALUE"))
			),
			( // Should succeed even if a valid AccessToken exists.
				prepareConfiguration: { _ in },
				response: .success("{\"access_token\":\"ACCESS_TOKEN_VALUE\"}"),
				expectedResult: .success(OAuthToken(rawValue: "ACCESS_TOKEN_VALUE"))
			),
		]

        let assertionsOnSuccess: Zone5.Result<OAuthToken>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.accessToken, rhs.accessToken)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, test in
			var configuration = ConfigurationForTesting()
			test.prepareConfiguration(&configuration)
			client.configure(with: configuration)

			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/oauth/access_token")
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])

				return test.response
			}

            let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            client.oAuth.accessToken(username: "username", password: "password", completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
	
	func testAdhocToken() {
		var expectedAuthToken = OAuthToken(token: "adhoc token", refresh: "refresh token", expiresIn: 123)
		expectedAuthToken.scope = "things"
		
		let tests: [(token: OAuthToken?, json: String, expectedResult: Zone5.Result<OAuthToken>)] = [
			(token:OAuthToken(token: "configured token", refresh: "refresh", username: "logged in user"), json:"{\"access_token\": \"adhoc token\", \"refresh\": \"refresh token\", \"scope\": \"things\", \"expires_in\":123}", expectedResult:.success(expectedAuthToken))
		]

        let assertionsOnSuccess: Zone5.Result<OAuthToken>.Expectation.SuccessAssertionsHandler = { lhs, rhs in
            XCTAssertEqual(lhs.accessToken, rhs.accessToken)
            XCTAssertEqual(lhs.expiresIn, rhs.expiresIn)
            XCTAssertEqual(lhs.scope, rhs.scope)
        }

        var expectations: [XCTestExpectation] = []
		execute(with: tests) { client, _, urlSession, expected in
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/oauth/newtoken/clientA")
				XCTAssertNotNil(request.allHTTPHeaderFields?["Authorization"])
				XCTAssertEqual("Bearer configured token", request.value(forHTTPHeaderField: "Authorization"))

				return .success("{\"access_token\": \"adhoc token\", \"refresh\": \"refresh token\", \"scope\": \"things\", \"expires_in\":123}")
			}

            let expectation = ResultExpectation(for: expected.expectedResult, assertionsOnSuccess: assertionsOnSuccess)
            expectations.append(expectation)

            client.oAuth.adhocAccessToken(for: "clientA", completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}
}
