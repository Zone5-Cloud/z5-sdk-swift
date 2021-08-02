import XCTest
@testable import Zone5

final class Zone5HTTPClientPerformRequestTests: XCTestCase {

	func testInvalidConfiguration() {
		var configuration = ConfigurationForTesting()
		configuration.baseURL = nil
		configuration.clientID = nil
		configuration.clientSecret = nil

        var expectations: [XCTestExpectation] = []
		for method:Zone5.Method in [.get, .post] {
			execute(configuration: configuration) { zone5, httpClient, urlSession in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

                let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.invalidConfiguration), assertionsOnSuccess: { _, _ in XCTFail() })
                expectations.append(expectation)

                _ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill)
			}
		}

        wait(for: expectations, timeout: 5)
	}

	func testMissingAccessToken() {
		var configuration = ConfigurationForTesting()
		configuration.accessToken = nil

		let tests: [(token: OAuthToken?, json: String, expectedResult: Zone5.Result<User>)] = [
            (token: nil, json: "", expectedResult: .failure(.serverError(.unauthorized)))
		]

        var expectations: [XCTestExpectation] = []
		for method: Zone5.Method in [.get, .post] {
			execute(with: tests, configuration: configuration) { zone5, httpClient, urlSession, test in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

                let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: { _, _ in XCTFail() })
                expectations.append(expectation)

                _ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill)
			}
		}

        wait(for: expectations, timeout: 5)
	}

	func testUnexpectedRequestBody() {
        let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.unexpectedRequestBody), assertionsOnSuccess: { _, _ in XCTFail() })

		execute { zone5, httpClient, urlSession in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: .get, body: SearchInputReport.forInstance(activityType: .workout, identifier: 12345))

			_ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: [expectation], timeout: 5)
	}
	
	func testError() throws {
		let json = "{\"message\": \"this is an error\", \"statusCode\": 401, \"errors\": [{\"field\": \"a field\", \"code\": 111, \"message\": \"a message\"}]}"
		let error = try decode(json: json, as: Zone5.Error.ServerMessage.self)
		XCTAssertEqual("this is an error", error.message)
		XCTAssertEqual(401, error.statusCode)
		XCTAssertEqual(1, error.errors?.count)
		XCTAssertEqual("a field", error.errors![0].field)
		XCTAssertEqual(111, error.errors![0].code)
		XCTAssertEqual("a message", error.errors![0].message)
		
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			var serverMessage = Zone5.Error.ServerMessage(message: "this is an error", statusCode: 401)
			serverMessage.errors = [Zone5.Error.ServerMessage.ServerError(field: "a field", message: "a message", code: 111)]
			
			urlSession.dataTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .failure(json, statusCode: 401)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.serverError(serverMessage)), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

			_ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

	func testServerFailure() {
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let serverMessage = Zone5.Error.ServerMessage(message: "A server error occurred.", statusCode: 500)

			urlSession.dataTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .message(serverMessage.message, statusCode: 500)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.serverError(serverMessage)), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

			_ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

	func testTransportFailure() {
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let transportError = Zone5.Error.unknown

			urlSession.dataTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .error(transportError)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.transportFailure(transportError)), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

            _ = httpClient.perform(request, expectedType: User.self, completion: expectation.fulfill(with:))
		}

        wait(for: expectations, timeout: 5)
	}

	func testSuccessfulRequest() {
		let parameters: [(method: Zone5.Method, params: URLEncodedBody?, body: RequestBody?)] = [
			(.get, nil, nil),
			(.get, ["string": "hello world", "integer": 1234567890] as URLEncodedBody, nil),
			(.post, ["string": "hello world", "integer": 1234567890] as URLEncodedBody, nil),
			(.post, ["string": "hello again", "integer": 0987654321] as URLEncodedBody, ["string": "hello world", "integer": 1234567890] as URLEncodedBody),
			(.post, ["string": "hello again", "integer": 0987654321] as URLEncodedBody, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
			(.post, nil, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
			(.post, nil, ["string": "hello world", "integer": 1234567890] as URLEncodedBody),
			(.post, nil, nil)
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, queryParams: parameters.params, body: parameters.body)

			urlSession.dataTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .success("{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}")
			}

            let expectation = XCTestExpectation()
            expectations.append(expectation)

            _ = httpClient.perform(request, expectedType: User.self) { result in
				if case .success(let user) = result {
					XCTAssertEqual(user.id, 12345678)
					XCTAssertEqual(user.email, "jame.smith@example.com")
					XCTAssertEqual(user.firstName, "Jane")
					XCTAssertEqual(user.lastName, "Smith")
				}
				else {
					XCTFail("\(parameters.method.rawValue) request unexpectedly completed with \(result).")
				}

                expectation.fulfill()
			}
		}

        wait(for: expectations, timeout: 5)
	}

}
