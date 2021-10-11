import XCTest
@testable import Zone5

final class Zone5HTTPClientUploadRequestTests: XCTestCase {

	private let developmentAssets = Bundle.tests.urlsForDevelopmentAssets()!.filter { $0.pathExtension != "multipart" }

	func testInvalidConfiguration() {
		var configuration = ConfigurationForTesting()
		configuration.baseURL = nil
		configuration.clientID = nil
		configuration.clientSecret = nil

		let tests: [(token: OAuthToken?, json: String, expectedResult: Zone5.Result<User>)] = [
            (token: nil, json: "", expectedResult: .failure(.invalidConfiguration))
		]

        var expectations: [XCTestExpectation] = []
		for method:Zone5.Method in [.get, .post] {
            execute(with: tests, configuration: configuration) { zone5, httpClient, urlSession, test in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

				let fileURL = developmentAssets.randomElement()
				XCTAssertNotNil(fileURL)

                let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: { _, _ in XCTFail() })
                expectations.append(expectation)

                _ = httpClient.upload(fileURL!, with: request, expectedType: User.self, completion: expectation.fulfill)
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
		for method:Zone5.Method in [.get, .post] {
			execute(with: tests, configuration: configuration) { zone5, httpClient, urlSession, test in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

				let fileURL = developmentAssets.randomElement()!

                let expectation = ResultExpectation(for: test.expectedResult, assertionsOnSuccess: { _, _ in XCTFail() })
                expectations.append(expectation)

                _ = httpClient.upload(fileURL, with: request, expectedType: User.self, completion: expectation.fulfill)
			}
		}

        wait(for: expectations, timeout: 5)
	}

	func testUnexpectedRequestBody() {
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
			(.post, ["string": "hello world", "integer": 1234567890] as URLEncodedBody),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let fileURL = developmentAssets.randomElement()!

			urlSession.uploadTaskHandler = { urlRequest, uploadedURL in
				XCTFail("Request should never be performed when encountering an unexpected request body.")

				return .error(Zone5.Error.unknown)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.unexpectedRequestBody), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

            _ = httpClient.upload(fileURL, with: request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

	func testServerFailure() {
		let parameters: [(method: Zone5.Method, body: JSONEncodedBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let fileURL = developmentAssets.randomElement()!
			XCTAssertNotNil(fileURL)

			let serverMessage = Zone5.Error.ServerMessage(message: "A server error occurred.", statusCode: 500)

			urlSession.uploadTaskHandler = { urlRequest, uploadedURL in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				if let uploadedData = try? Data(contentsOf: uploadedURL), let contentType = urlRequest.allHTTPHeaderFields?["Content-Type"] {
					var expectations: [String: MultipartEncodedBodyTests.Expectation] = [
						"filename": .object(fileURL.lastPathComponent),
						"attachment": .file(fileURL),
					]

					if let body = parameters.body {
						expectations["json"] = .object(body)
					}

					MultipartEncodedBodyTests.validate(uploadedData, with: contentType, against: expectations)
				}
				else {
					XCTFail("Expected uploaded file to have data and a Content-Type to go with it.")
				}

				return .message(serverMessage.message, statusCode: 500)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.serverError(serverMessage)), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

            _ = httpClient.upload(fileURL, with: request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

	func testTransportFailure() {
		let parameters: [(method: Zone5.Method, body: JSONEncodedBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

        var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let fileURL = developmentAssets.randomElement()!
			let transportError = Zone5.Error.unknown

			urlSession.uploadTaskHandler = { urlRequest, uploadedURL in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				if let uploadedData = try? Data(contentsOf: uploadedURL), let contentType = urlRequest.allHTTPHeaderFields?["Content-Type"] {
					var expectations: [String: MultipartEncodedBodyTests.Expectation] = [
						"filename": .object(fileURL.lastPathComponent),
						"attachment": .file(fileURL),
					]

					if let body = parameters.body {
						expectations["json"] = .object(body)
					}

					MultipartEncodedBodyTests.validate(uploadedData, with: contentType, against: expectations)
				}
				else {
					XCTFail("Expected uploaded file to have data and a Content-Type to go with it.")
				}

				return .error(transportError)
			}

            let expectation = ResultExpectation(for: Zone5.Result<User>.failure(.transportFailure(transportError)), assertionsOnSuccess: { _, _ in XCTFail() })
            expectations.append(expectation)

            _ = httpClient.upload(fileURL, with: request, expectedType: User.self, completion: expectation.fulfill)
		}

        wait(for: expectations, timeout: 5)
	}

	func testSuccessfulRequest() {
		let parameters: [(method: Zone5.Method, body: JSONEncodedBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

		var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let fileURL = developmentAssets.randomElement()!

			urlSession.uploadTaskHandler = { urlRequest, uploadedURL in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				if let uploadedData = try? Data(contentsOf: uploadedURL), let contentType = urlRequest.allHTTPHeaderFields?["Content-Type"] {
					var expectations: [String: MultipartEncodedBodyTests.Expectation] = [
						"filename": .object(fileURL.lastPathComponent),
						"attachment": .file(fileURL),
					]

					if let body = parameters.body {
						expectations["json"] = .object(body)
					}

					MultipartEncodedBodyTests.validate(uploadedData, with: contentType, against: expectations)
				}
				else {
					XCTFail("Expected uploaded file to have data and a Content-Type to go with it.")
				}

				return .success("{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}")
			}

			let expectation = XCTestExpectation()
			expectations.append(expectation)

			_ = httpClient.upload(fileURL, with: request, expectedType: User.self) { result in
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

	func testRateLimiting() {
		let parameters = [Zone5.Method](repeating: .get, count: 100)

		var tasksInProgress = 0
		var expectations: [XCTestExpectation] = []
		execute(with: parameters) { zone5, httpClient, urlSession, method in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method, body: nil)

			let fileURL = developmentAssets.randomElement()!

			urlSession.uploadTaskHandler = { urlRequest, uploadedURL in
				DispatchQueue.main.async {
					tasksInProgress += 1
					XCTAssertTrue(tasksInProgress <= Zone5HTTPClient.downloadQueue.maxConcurrentOperationCount)
				}

				usleep(.random(in: 1000...10000)) // Give the tasks a chance to back up

				return .success("{\"id\": 12345678, \"email\": \"jame.smith@example.com\", \"firstname\": \"Jane\", \"lastname\": \"Smith\"}")
			}

			let expectation = XCTestExpectation()
			expectations.append(expectation)

			_ = httpClient.upload(fileURL, with: request, expectedType: User.self) { result in
				DispatchQueue.main.async {
					tasksInProgress -= 1
					XCTAssertTrue(tasksInProgress <= Zone5HTTPClient.downloadQueue.maxConcurrentOperationCount)
				}

				expectation.fulfill()
			}
		}

		wait(for: expectations, timeout: 5)
	}

}
