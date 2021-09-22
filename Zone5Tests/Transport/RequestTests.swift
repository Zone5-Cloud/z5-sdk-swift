import XCTest
@testable import Zone5

final class RequestTests: XCTestCase {

	enum Endpoints: String, RequestEndpoint {
		case test = "endpoint/uri"
	}

	var zone5: Zone5!
	
	let baseURL = URL(string: "https://localhost")!

	override func setUpWithError() throws {
		// configure auth token
		zone5 = createNewZone5()
		zone5.configure(for: baseURL, userAgent: "testagent/1.1.1 (222)", accessToken: OAuthToken(token: UUID().uuidString))
	}
	
	func testRequest() {
		let body: URLEncodedBody = [
			"example": "example"
		]

		let request = Request(endpoint: Endpoints.test, method: .post, body: body)

		do {
			let urlRequest = try request.urlRequest(zone5: zone5, taskType: .data)

			XCTAssertNotNil(urlRequest.httpBody)
			XCTAssertNil(urlRequest.value(forHTTPHeaderField: "User-Agent"))
			
			let urlRequest2 = URLRequestInterceptor.decorate(request: try request.urlRequest(zone5: zone5, taskType: .download))

			XCTAssertNotNil(urlRequest2.httpBody)
			XCTAssertEqual("testagent/1.1.1 (222)", urlRequest2.value(forHTTPHeaderField: "User-Agent"))
			
//			let decoded = try JSONDecoder().decode(URLEncodedBody.self, from: urlRequest.httpBody!)
//
//			XCTAssertNotNil(decoded)
//			XCTAssertEqual(decoded, body)
		}
		catch {
			print(error)

			XCTFail()
		}
	}
	
	func testRequest2() {
		let body: URLEncodedBody = [
			"example": nil
		]
		
		let request = Request(endpoint: Endpoints.test, method: .post, body: body)
		
		do {
			let urlRequest = try request.urlRequest(zone5: zone5, taskType: .data)
			
			XCTAssertNotNil(urlRequest.httpBody)
			
			//			let decoded = try JSONDecoder().decode(URLEncodedBody.self, from: urlRequest.httpBody!)
			//
			//			XCTAssertNotNil(decoded)
			//			XCTAssertEqual(decoded, body)
		}
		catch {
			print(error)
			
			XCTFail()
		}
	}
}
