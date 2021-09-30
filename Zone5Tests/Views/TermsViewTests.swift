//
//  TermsViewTests.swift
//  Zone5Tests
//
//  Created by Jean Hall on 23/9/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class TermsViewTests: XCTestCase {

    func testRequired() throws {
		let expectation = self.expectation(description: "required returned")
		
		self.execute(with: ["[ {\"companyId\":\"4ad6d516-3f3f-4efb-a9b0-3e81a5d4745d\",\"termsId\":\"Specialized_Terms\",\"displayName\":\"Specialized Terms and Conditions\",\"version\":1,\"displayVersion\":\"v1\",\"entityType\":\"oauthapp\",\"active\":true,\"status\":\"active\",\"alias\":\"Specialized_Terms\",\"url\":\"https://www.specialized.com/au/en/terms-and-conditions\"},{\"companyId\":\"4ad6d516-3f3f-4efb-a9b0-3e81a5d4745d\",\"termsId\":\"Specialized_Terms_Apps\",\"displayName\":\"Specialized Terms of Use\",\"version\":2,\"displayVersion\":\"v2\",\"entityType\":\"oauthapp\",\"active\":true,\"status\":\"active\",\"alias\":\"Specialized_Terms_Apps\",\"url\":\"https://www.specialized.com/au/en/terms-of-use\"}]"]) { z5, _, urlSession, test in
			
			urlSession.dataTaskHandler = { request in
				// endpoint url
				XCTAssertEqual(request.url?.path, "/rest/auth/terms/required")
				// unauthenticated endpoint
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])

				return .success(test)
			}
			
			//let expected = JSONDecoder().decode([TermsAndConditions.self], from: test.data(using: .utf8))

			z5.terms.required { result in
				if case .success(let terms) = result {
					XCTAssertEqual(terms.count, 2)
					XCTAssertEqual(terms[0].termsId, "Specialized_Terms")
					XCTAssertEqual(terms[0].alias, "Specialized_Terms")
					XCTAssertEqual(terms[0].version, 1)
					XCTAssertEqual(terms[0].displayVersion, "v1")
					XCTAssertEqual(terms[0].displayName, "Specialized Terms and Conditions")
					XCTAssertEqual(terms[0].companyId, "4ad6d516-3f3f-4efb-a9b0-3e81a5d4745d")
					XCTAssertEqual(terms[0].url, URL(string: "https://www.specialized.com/au/en/terms-and-conditions")!)
					
					XCTAssertEqual(terms[1].termsId, "Specialized_Terms_Apps")
					XCTAssertEqual(terms[1].alias, "Specialized_Terms_Apps")
					XCTAssertEqual(terms[1].version, 2)
					XCTAssertEqual(terms[1].displayVersion, "v2")
					XCTAssertEqual(terms[1].displayName, "Specialized Terms of Use")
					XCTAssertEqual(terms[1].companyId, "4ad6d516-3f3f-4efb-a9b0-3e81a5d4745d")
					XCTAssertEqual(terms[1].url, URL(string: "https://www.specialized.com/au/en/terms-of-use")!)
					
				} else {
					XCTAssert(false, "Unexpected failure")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
    }


	func testRequiredFailures() throws {
		let expectation = self.expectation(description: "required returned")
		expectation.expectedFulfillmentCount = 3
		
		execute(with: [TestHTTPClientURLSession.Result<String>.success("{\"fail\":\"decoding\"}"), TestHTTPClientURLSession.Result<String>.error(Zone5.Error.invalidParameters), TestHTTPClientURLSession.Result<String>.message("Not Found", statusCode: 404)]) { z5, _, urlSession, test in
			urlSession.dataTaskHandler = { request in
				// endpoint url
				XCTAssertEqual(request.url?.path, "/rest/auth/terms/required")
				// unauthenticated endpoint
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])

				return test
			}
			
			z5.terms.required { result in
				if case .failure(let error) = result {
					if case .success(_) = test, case .failedDecodingResponse(_) = error {
						// good
					} else if case .error(_) = test, case .transportFailure(let internalError) = error, case Zone5.Error.invalidParameters = internalError {
						// good
					}  else if case .message(let expectedMessage, let expectedStatusCode) = test, case Zone5.Error.serverError(let msg) = error {
						XCTAssertEqual(expectedStatusCode, msg.statusCode)
						XCTAssertEqual(expectedMessage, msg.message)
					} else {
						XCTAssert(false, "unexpected response")
					}
				} else {
					XCTAssert(false, "Unexpected success")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testAccept() throws {
		let expectation = self.expectation(description: "accept returned")
		execute(with: ["test-terms-id"]) { z5, _, urlSession, test in
			
			urlSession.dataTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/terms/accept/\(test)")
				// authenticated endpoint
				XCTAssertNotNil(request.allHTTPHeaderFields?["Authorization"])
				
				// empty body
				return .success("")
			}
			
			z5.terms.accept(termsID: test) { result in
				if case .success(_) = result {
					// all good
				} else {
					XCTAssert(false, "unexpected result")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testDownload() throws {
		let expectation = self.expectation(description: "accept returned")
		let testFile = Bundle.tests.urlsForDevelopmentAssets()!.first { $0.pathExtension == "html" }!
		XCTAssert(FileManager.default.fileExists(atPath: testFile.path))
		execute(with: ["test-terms-id"]) { z5, _, urlSession, test in
			
			urlSession.downloadTaskHandler = { request in
				XCTAssertEqual(request.url?.path, "/rest/auth/terms/download/\(test)")
				// unauthenticated endpoint
				XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
				
				// empty body
				return .success(testFile)
			}
			
			z5.terms.download(termsID: test) { result in
				if case .success(let url) = result {
					XCTAssert(FileManager.default.fileExists(atPath: url.path))
					XCTAssert(FileManager.default.contentsEqual(atPath: url.path, andPath: testFile.path))
				} else {
					XCTAssert(false, "unexpected result")
				}
				
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
}
