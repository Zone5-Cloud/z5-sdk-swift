//
//  XCTestCase.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 19/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

extension XCTestCase {

	struct ConfigurationForTesting {

		var accessToken: AccessToken? = OAuthToken(token: "ACCESS_TOKEN", refresh: "REFRESH_TOKEN", tokenExp: Date().addingTimeInterval(60000).milliseconds.rawValue, username: "testuser")

		var baseURL: URL? = URL(string: "http://localhost")!

		var clientID: String? = "CLIENT_IDENTIFIER"

		var clientSecret: String? = "CLIENT_SECRET"

		var redirectURI: String = "https://localhost"

	}

	enum EndpointsForTesting: String, RequestEndpoint {

		/// Basic endpoint that does not require an access token.
		case `default` = "/endpoint/default"

		/// Basic endpoint that requires an access token.
		case requiresAccessToken = "/endpoint/noAccessTokenRequired"

		/// Endpoint with a replaceable `{token}` that does not require an access token.
		case withReplaceableTokens = "/endpoint/with/{token}"

		var requiresAccessToken: Bool {
			switch self {
			case .requiresAccessToken: return true
			default: return false
			}
		}
	}
	
    var authFailure: Zone5.Error { return .serverError(.unauthorized) }
	
	func createNewZone5() -> Zone5 {
		let urlSession = TestHTTPClientURLSession()
		let httpClient = Zone5HTTPClient(urlSession: urlSession)
		return Zone5(httpClient: httpClient)
	}
	

	func execute(configuration: ConfigurationForTesting = .init(), _ tests: (_ zone5: Zone5, _ httpClient: Zone5HTTPClient, _ urlSession: TestHTTPClientURLSession) throws -> Void) rethrows {
		let urlSession = TestHTTPClientURLSession()
		let httpClient = Zone5HTTPClient(urlSession: urlSession)
		
		let zone5 = Zone5(httpClient: httpClient)
		zone5.configure(with: configuration)

		try tests(zone5, httpClient, urlSession)
	}

	typealias P<T:Decodable> = (token:AccessToken?, json:String, expectedResult:Zone5.Result<T>)

	func execute<T>(with parameters: [P<T>], configuration: ConfigurationForTesting = .init(), _ tests: (_ zone5: Zone5, _ httpClient: Zone5HTTPClient, _ urlSession: TestHTTPClientURLSession, _ parameters: P<T>) throws -> Void) rethrows {
		try parameters.forEach { parameter in
			try execute(configuration: configuration) { zone5, httpClient, urlSession in
				zone5.accessToken = parameter.token
				urlSession.dataTaskHandler = { request in
					if let token = parameter.token, let required = request.getMeta(key: .requiresAccessToken) as? Bool, required {
						// auth header present
						XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer \(token.rawValue)")
						return .success(parameter.json)
					} else if let required = request.getMeta(key: .requiresAccessToken) as? Bool, required {
						// missing required auth header
						XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
						return .failure("Unauthorized", statusCode: 401)
					} else {
						// auth header not required
						XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
						return .success(parameter.json)
					}
				}

                urlSession.uploadTaskHandler = { request, fileURL in
					return urlSession.dataTaskHandler!(request)
				}

                try tests(zone5, httpClient, urlSession, parameter)
			}
		}
	}

	func execute<T>(with parameters: [T], configuration: ConfigurationForTesting = .init(), _ tests: (_ zone5: Zone5, _ httpClient: Zone5HTTPClient, _ urlSession: TestHTTPClientURLSession, _ parameters: T) throws -> Void) rethrows {
		try parameters.forEach { parameter in
			try execute(configuration: configuration) { zone5, httpClient, urlSession in
				try tests(zone5, httpClient, urlSession, parameter)
			}
		}
	}

    /// Convenience method to quickly decode a JSON string as the given `expectedType`.
	func decode<T: Decodable>(json: String, as expectedType: T.Type) throws -> T {
		return try JSONDecoder().decode(expectedType, from: json.data(using: .utf8)!)
	}

	/// Convenience method to quickly decode a JSON string as the given `expectedType`.
	func encode<T: Encodable>(_ value: T) throws -> String {
		let data = try JSONEncoder().encode(value)
		return String(data: data, encoding: .utf8)!
	}

}

extension Zone5 {

	func configure(with configuration: XCTestCase.ConfigurationForTesting) {
		redirectURI = configuration.redirectURI
		accessToken = configuration.accessToken

		if let baseURL = configuration.baseURL, let clientID = configuration.clientID, let clientSecret = configuration.clientSecret {
			configure(for: baseURL, clientID: clientID, clientSecret: clientSecret)
		}
		else {
			baseURL = configuration.baseURL
			clientID = configuration.clientID
			clientSecret = configuration.clientSecret
		}
	}

}
