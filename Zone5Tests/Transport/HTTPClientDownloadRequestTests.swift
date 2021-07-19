import XCTest
@testable import Zone5

final class Zone5HTTPClientDownloadRequestTests: XCTestCase {

	private let developmentAssets = Bundle.tests.urlsForDevelopmentAssets()!.filter { $0.pathExtension != "multipart" }

	func testInvalidConfiguration() {
		// explicitly set baseURL to nil. This will cause the request to fail early with invalid configuration
		// the request should never be executed
		var configuration = ConfigurationForTesting()
		configuration.baseURL = nil

		for method: Zone5.Method in [.get, .post] {
			execute(configuration: configuration) { zone5, httpClient, urlSession in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

				urlSession.downloadTaskHandler = { urlRequest in
					XCTFail("Request should never be performed when invalidly configured.")

					return .error(Zone5.Error.unknown)
				}

				_ = httpClient.download(request) { result in
					if case .failure(let error) = result,
						case .invalidConfiguration = error {
							return // Success!
					}

					XCTFail("\(method.rawValue) request unexpectedly completed with \(result).")
				}
			}
		}
	}

	func testMissingAccessToken() {
		var configuration = ConfigurationForTesting()
		configuration.accessToken = nil

		for method: Zone5.Method in [.get, .post] {
			execute(configuration: configuration) { zone5, httpClient, urlSession in
				let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: method)

				urlSession.downloadTaskHandler = { urlRequest in
					XCTAssertNil(urlRequest.allHTTPHeaderFields?["Authorization"])
					return .failure("Unauthorized", statusCode: 401)
				}
				
				_ = httpClient.download(request) { result in
					if case .failure(let error) = result, case .serverError(let message) = error, message.statusCode == 401 {
						return // Success!
					}

					XCTFail("\(method.rawValue) request unexpectedly completed with \(result).")
				}
			}
		}
	}

	func testUnexpectedRequestBody() {
		execute { zone5, httpClient, urlSession in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: .get, body: SearchInputReport.forInstance(activityType: .workout, identifier: 12345))

			urlSession.downloadTaskHandler = { urlRequest in
				XCTFail("Request should never be performed when encountering an unexpected request body.")

				return .error(Zone5.Error.unknown)
			}

			_ = httpClient.download(request) { result in
				if case .failure(let error) = result,
					case .unexpectedRequestBody = error {
						return // Success!
				}

				XCTFail("Request unexpectedly completed with \(result).")
			}
		}
	}

	func testServerFailure() {
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let serverMessage = Zone5.Error.ServerMessage(message: "A server error occurred", statusCode: 500)

			urlSession.downloadTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .message(serverMessage.message, statusCode: 500)
			}

			_ = httpClient.download(request, completion: { result in
				if case .failure(let error) = result,
					case .serverError(let message) = error,
					message == serverMessage {
						return // Success!
				}

				XCTFail("\(parameters.method.rawValue) request unexpectedly completed with \(result).")
			})
		}
	}

	func testTransportFailure() {
		let parameters: [(method: Zone5.Method, body: RequestBody?)] = [
			(.get, nil),
			(.post, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)),
		]

		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, body: parameters.body)

			let transportError = Zone5.Error.unknown

			urlSession.downloadTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, parameters.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .error(transportError)
			}

			_ = httpClient.download(request) { result in
				if case .failure(let error) = result,
					case .transportFailure(let underlyingError) = error,
					(underlyingError as NSError).domain == (transportError as NSError).domain,
					(underlyingError as NSError).code == (transportError as NSError).code {
						return // Success!
				}

				XCTFail("\(parameters.method.rawValue) request unexpectedly completed with \(result).")
			}
		}
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

        execute(with: parameters) { zone5, httpClient, urlSession, parameters in
            let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, queryParams: parameters.params, body: parameters.body)

            let fileUUID = UUID().uuidString
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Zone5HTTPClientDownloadRequestTests.testSuccessfulRequest.\(fileUUID).tmp")
            try! fileUUID.write(to: fileURL, atomically: true, encoding: .utf8)

            urlSession.downloadTaskHandler = { urlRequest in
                XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
                XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
                XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

                return .success(fileURL)
            }

            _ = httpClient.download(request) { result in
                if case .success(let downloadedURL) = result {
                    XCTAssert(FileManager.default.contentsEqual(atPath: downloadedURL.path, andPath: fileURL.path))
                }
                else {
                    XCTFail("\(parameters.method.rawValue) request using parameters (\(parameters.params?.description ?? "none")) unexpectedly completed with \(result).")
                }

                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
	
	func testFailedRequest() {
		let parameters: [(method: Zone5.Method, params: URLEncodedBody?, body: RequestBody?)] = [
			(.get, nil, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)), // get cannot have body
			(.get, ["string": "hello world", "integer": 1234567890] as URLEncodedBody, SearchInputReport.forInstance(activityType: .workout, identifier: 12345)), // get cannot have body
			(.get, nil, ["string": "hello world", "integer": 1234567890] as URLEncodedBody), // get cannot have body
			(.get, ["string": "hello world", "integer": 1234567890] as URLEncodedBody, ["string": "hello world", "integer": 1234567890] as URLEncodedBody), // get cannot have body
			// post can have any combo
		]

		execute(with: parameters) { zone5, httpClient, urlSession, parameters in
			let request = Request(endpoint: EndpointsForTesting.requiresAccessToken, method: parameters.method, queryParams: parameters.params, body: parameters.body)
			let fileURL = developmentAssets.randomElement()!

			urlSession.downloadTaskHandler = { urlRequest in
				XCTAssertEqual(urlRequest.url?.path, request.endpoint.uri)
				XCTAssertEqual(urlRequest.httpMethod, request.method.rawValue)
				XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(zone5.accessToken!)")

				return .success(fileURL)
			}

			_ = httpClient.download(request) { result in
				if case .failure(let error) = result,
				   case .unexpectedRequestBody = error {
						return // Success!
				}

				XCTFail("\(parameters.method.rawValue) request unexpectedly completed with \(result).")
			}
		}
	}
}
