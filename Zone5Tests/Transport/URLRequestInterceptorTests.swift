//
//  URLRequestInterceptorTests.swift
//  Zone5Tests
//
//  Created by Jean Hall on 24/11/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class URLRequestInterceptorTests: XCTestCase {
	private var urlSession = TestHTTPClientURLSession()
	private var zone5: Zone5!
	
	override func setUpWithError() throws {
		zone5 = Zone5(httpClient: .init(urlSession: urlSession))
		// configure auth token that is not near expiry
		var oauth = OAuthToken(rawValue: "testauth")
		oauth.refreshToken = "refresh"
		oauth.tokenExp = Date().milliseconds.rawValue + 100000
		zone5.configure(for: URL(string: "https://api-sp-staging.todaysplan.com.au")!, clientID: "CLIENT ID", clientSecret: "CLIENT SECRET", userAgent: "agent 123", accessToken: oauth)
	}

	
    func testNoAuth() throws {
		let request = createRequest("/rest/test", authRequired: false)
		XCTAssertTrue(URLRequestInterceptor.canInit(with: request))
		
		let interceptor = SpyURLRequestInterceptor(request)
		XCTAssertNil(interceptor.lastRequest)
		XCTAssertEqual(request, interceptor.request)
		
		interceptor.startLoading()
		
		XCTAssertNotNil(interceptor.lastRequest)
		XCTAssertEqual(request.url, interceptor.lastRequest!.url)
		XCTAssertEqual(URLSessionTaskType.data, interceptor.lastRequest?.taskType)
		// should be no auth header
		XCTAssertNil(interceptor.lastRequest!.value(forHTTPHeaderField: "Authorization"))
		
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key"), "CLIENT ID")
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key-Secret"), "CLIENT SECRET")
	}

	func testAuthNotExpiredData() {
		testAuthNotExpired(taskType: .data)
	}
	
	func testAuthNotExpiredUpload() {
		testAuthNotExpired(taskType: .upload)
	}
	
	func testAuthNotExpiredDownload() {
		testAuthNotExpired(taskType: .download)
	}
	
	private func testAuthNotExpired(taskType: URLSessionTaskType) {
		var request = createRequest("/rest/test", authRequired: true)
		request = request.setMeta(key: .taskType, value: taskType)
		
		let interceptor = SpyURLRequestInterceptor(request)
		XCTAssertNil(interceptor.lastRequest)
		XCTAssertEqual(request, interceptor.request)
		
		interceptor.startLoading()
		
		XCTAssertNotNil(interceptor.lastRequest)
		XCTAssertEqual(request.url, interceptor.lastRequest!.url)
		XCTAssertEqual(taskType, interceptor.lastRequest!.taskType)
		// suth header should be set
		XCTAssertEqual("Bearer testauth", interceptor.lastRequest!.value(forHTTPHeaderField: "Authorization"))
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key"), "CLIENT ID")
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key-Secret"), "CLIENT SECRET")
	}
	
	func testAuthExpired() {
		let request = createRequest("/rest/test", authRequired: true)
		
		// configure auth token that is near expiry
		var oauth = OAuthToken(rawValue: "testauth")
		oauth.refreshToken = "refresh"
		oauth.tokenExp = Date().milliseconds.rawValue
		zone5.accessToken = oauth
		
		// refresh is asynchronous so we need to set up expectations and capture the intermediary step to test validity
		let expectation = self.expectation(description: "sendRequest called")
		expectation.expectedFulfillmentCount = 1
		
		let interceptor = SpyURLRequestInterceptor(request, expectation: expectation)
		XCTAssertNil(interceptor.lastRequest)
		XCTAssertEqual(request, interceptor.request)
		
		// the refresh should go through the test session and hit here
		urlSession.dataTaskHandler = { request in
			XCTAssertEqual(request.url?.path, "/rest/oauth/access_token")
			// token refresh is an unauthenticated request that passes the refresh token. Should not have auth header
			XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

			return .success("{\"access_token\":\"testauth\", \"refresh_token\":\"123\", \"expires_in\":30000}")
		}
		
		// before refresh token updated
		XCTAssertEqual("refresh", (zone5.accessToken as! OAuthToken).refreshToken)
		
		// kick it off
		interceptor.startLoading()
		
		// wait for async callbacks
		wait(for: [expectation], timeout: 5)
		
		// refresh should have triggered, our refresh token on the zone5 instance should've been updated and the original request should've fired
		XCTAssertNotNil(interceptor.lastRequest)
		XCTAssertEqual(request.url, interceptor.lastRequest!.url)
		XCTAssertEqual(URLSessionTaskType.data, interceptor.lastRequest!.taskType)
		XCTAssertEqual("123", (zone5.accessToken as! OAuthToken).refreshToken) // no longer "refresh"
		// auth header should be added
		XCTAssertNil(interceptor.request.value(forHTTPHeaderField: "Authorization"))
		XCTAssertEqual("Bearer testauth", interceptor.lastRequest!.value(forHTTPHeaderField: "Authorization"))
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key"), "CLIENT ID")
		XCTAssertEqual(interceptor.lastRequest!.value(forHTTPHeaderField: "Api-Key-Secret"), "CLIENT SECRET")
	}
	
	func testAuthExpiredPipelineOnlyRefreshesOnce() {
		// configure auth token that is near expiry
		var oauth = OAuthToken(rawValue: "testauth")
		oauth.refreshToken = "refresh"
		oauth.tokenExp = Date().milliseconds.rawValue
		zone5.accessToken = oauth
		
		// refresh is asynchronous so we need to set up expectations and capture the intermediary step to test validity
		let expectationSendRequest = self.expectation(description: "sendRequest called")
		expectationSendRequest.expectedFulfillmentCount = 5
		
		// create 5 requests
		let interceptors: [SpyURLRequestInterceptor] = [SpyURLRequestInterceptor(createRequest("/rest/first", authRequired: true), expectation: expectationSendRequest),
													 SpyURLRequestInterceptor(createRequest("/rest/second", authRequired: true), expectation: expectationSendRequest),
													 SpyURLRequestInterceptor(createRequest("/rest/third", authRequired: true), expectation: expectationSendRequest),
													 SpyURLRequestInterceptor(createRequest("/rest/fourth", authRequired: true), expectation: expectationSendRequest),
													 SpyURLRequestInterceptor(createRequest("/rest/fifth", authRequired: true), expectation: expectationSendRequest)]
		
		// the refresh should go through the test session and hit here, there should only be 1 refresh triggered
		let expectationRefresh = self.expectation(description: "refresh called only once")
		expectationRefresh.assertForOverFulfill = true
		expectationRefresh.expectedFulfillmentCount = 1
		urlSession.dataTaskHandler = { request in
			XCTAssertEqual(request.url?.path, "/rest/oauth/access_token")
			// token refresh is an unauthenticated request that passes the refresh token. Should not have auth header
			XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

			expectationRefresh.fulfill()
			print("refresh called")
			return .success("{\"access_token\":\"testauth\", \"refresh_token\":\"123\", \"expires_in\":30000}")
		}
		
		// before refresh token updated
		XCTAssertEqual("refresh", (zone5.accessToken as! OAuthToken).refreshToken)
		
		// kick it off 5 times concurrently and asynchronously
		let queue = DispatchQueue(label: "testqueue", attributes: .concurrent)
		interceptors.forEach { let a = $0; queue.async { a.startLoading() } }
		
		// wait for async callbacks. all 5 requests should get called. Only one refresh (the first one).
		wait(for: [expectationSendRequest, expectationRefresh], timeout: 5)
		
		// refresh should have triggered, our refresh token on the zone5 instance should've been updated and the original request should've fired
		interceptors.forEach {
			XCTAssertNotNil($0.lastRequest)
			XCTAssertEqual($0.request.url, $0.lastRequest!.url)
			XCTAssertEqual(URLSessionTaskType.data, $0.lastRequest!.taskType)
			
			// the authorization header is added during startLoading
			XCTAssertNil($0.request.value(forHTTPHeaderField: "Authorization"))
			XCTAssertEqual("Bearer testauth", $0.lastRequest!.value(forHTTPHeaderField: "Authorization"))
			XCTAssertEqual($0.lastRequest!.value(forHTTPHeaderField: "Api-Key"), "CLIENT ID")
			XCTAssertEqual($0.lastRequest!.value(forHTTPHeaderField: "Api-Key-Secret"), "CLIENT SECRET")
		}
		
		XCTAssertEqual("123", (zone5.accessToken as! OAuthToken).refreshToken) // no longer "refresh"
	}
	
	private func createRequest(_ url: String, authRequired: Bool) -> URLRequest{
		var request = URLRequest(url: URL(string: url)!)
		// require auth token
		if authRequired {
			request = request.setMeta(key: .requiresAccessToken, value: true)
		}
		request = request.setMeta(key: .zone5, value: zone5!)
		return request
	}
}

class SpyURLRequestInterceptor: URLRequestInterceptor {
	var lastRequest: URLRequest? = nil
	var expectation: XCTestExpectation?
	
	init(_ request: URLRequest, expectation: XCTestExpectation? = nil) {
		super.init(request: request, cachedResponse: nil, client: nil)
		self.expectation = expectation
	}
	
	override func sendRequest(_ request: URLRequest) {
		lastRequest = request
		print("sendRequest: \(request.url!)")
		expectation?.fulfill()
	}
	
	override internal func extractUsername(from jwt: String) -> String? {
		return "testuser"
	}
}
