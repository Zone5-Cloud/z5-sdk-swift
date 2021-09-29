//
//  Zone5Tests.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 6/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class Zone5Tests: XCTestCase {
	
	var z5: Zone5!
	
	override func setUp() {
		z5 = createNewZone5()
	}
	
	func testAccessToken() {
		XCTAssertNil(z5.accessToken)
		let now = Date()
		
		let oAuth = OAuthToken(token: "abc", refresh: "zxc", expiresIn: 300.0)
		
		XCTAssertNotNil(oAuth.tokenExp)
		
		if let expiresAt = oAuth.tokenExp {
			XCTAssertTrue(expiresAt >= now.addingTimeInterval(300).milliseconds)
			XCTAssertTrue(expiresAt <= Date().addingTimeInterval(300).milliseconds)
		}
		
		z5.accessToken = oAuth
		
		XCTAssertTrue(oAuth.equals(z5.accessToken))
	}
	
	func testFieldName() {
		XCTAssertEqual(["headunit.manufacturer"], UserHeadunit.fields([.manufacturer], prefix: "headunit"))
		XCTAssertEqual(["turbo.numAssistChanges", "turbo.avgAssist"], UserWorkoutResultTurbo.fields([.assistChanges, .averageAssist], prefix: "turbo"))
		XCTAssertEqual(["turboExt.avgBattery1Temperature", "turboExt.avgGPSSpeed"], UserWorkoutResultTurboExt.fields([.averageBattery1Temperature, .averageGPSSpeed], prefix: "turboExt"))
	}
	
	func testAccessTokenUpdated() {
		let token = OAuthToken(token: "123")
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5) { notification in
			XCTAssertEqual(notification.userInfo?["accessToken"] as? OAuthToken, token)
			return true
		}
		
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		
		z5.configure(for: URL(string: "http://test")!, accessToken: token)
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual(token, z5.accessToken as? OAuthToken)
	}
	
	func testAccessTokenOnChanged() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
		XCTAssertEqual(4, z5.accessToken?.tokenExp)
		XCTAssertNotNil(z5.accessToken?.expiresIn)
	}
	
	func testAccessTokenOnChanged2() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		XCTAssertEqual(4, z5.accessToken?.tokenExp)
		XCTAssertNotNil(z5.accessToken?.expiresIn)
		
		let token = OAuthToken(token: "123", refresh: "zxc", tokenExp: 5 as Milliseconds, username: "")
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5) { notification in
			XCTAssertEqual(token, notification.userInfo?["accessToken"] as? OAuthToken)
			return true
		}
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: token)
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
		XCTAssertEqual(5, z5.accessToken?.tokenExp)
		XCTAssertNotNil(z5.accessToken?.expiresIn)
	}
	
	func testAccessTokenOnChanged3() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc1", tokenExp: 4 as Milliseconds, username: ""))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
		XCTAssertEqual(4, z5.accessToken?.tokenExp)
		XCTAssertNotNil(z5.accessToken?.expiresIn)
	}
	
	func testAccessTokenUpdatedOnNil() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: nil)
		wait(for: [expectation], timeout: 5)
		XCTAssertNil(z5.accessToken?.rawValue)
	}
	
	func testAccessTokenUpdatedOnNil2() {
		z5.configure(for: URL(string: "http://test")!, accessToken: nil)
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenNotUpdatedWhenSame() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.isInverted = true
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123"))
		wait(for: [expectation], timeout: 1)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenNotUpdatedWhenSame2() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.isInverted = true
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: ""))
		wait(for: [expectation], timeout: 1)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenNotUpdatedWhenSameNil() {
		z5.configure(for: URL(string: "http://test")!, accessToken: nil)
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.isInverted = true
		
		z5.configure(for: URL(string: "http://test")!, accessToken: nil)
		wait(for: [expectation], timeout: 1)
		XCTAssertNil(z5.accessToken?.rawValue)
	}
	
	func testAccessTokenOnChangedAlt() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
		XCTAssertNil(z5.accessToken?.tokenExp)
		XCTAssertNil(z5.accessToken?.expiresIn)
	}
	
	func testAccessTokenOnChangedAlt2() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123"))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenOnChangedAlt3() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "1234"))
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("1234", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenOnChangedAlt4() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		var oauth = OAuthTokenAlt(rawValue: "123")
		oauth.tokenExp = 6
		z5.configure(for: URL(string: "http://test")!, accessToken: oauth)
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenOnChangedAlt5() {
		z5.configure(for: URL(string: "http://test")!, accessToken: nil)
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.assertForOverFulfill = true
		expectation.expectedFulfillmentCount = 1
		
		var oauth = OAuthTokenAlt(rawValue: "123")
		oauth.tokenExp = 6
		z5.configure(for: URL(string: "http://test")!, accessToken: oauth)
		wait(for: [expectation], timeout: 5)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenNotChangedAlt() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		expectation.isInverted = true
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthTokenAlt(rawValue: "123"))
		wait(for: [expectation], timeout: 1)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenUsername() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: "testuser@gmail.com"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5) { notification in
			let token = notification.userInfo?["accessToken"] as? OAuthToken
			XCTAssertNotNil(token)
			XCTAssertEqual("new username", token!.username)
			return true
		}
		
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: "new username"))
		wait(for: [expectation], timeout: 1)
		
		XCTAssertEqual("new username", z5.accessToken?.username)
		XCTAssertEqual("123", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenNewUsername() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "123", refresh: "zxc", tokenExp: 4 as Milliseconds, username: "testuser@gmail.com"))
		
		let expectation = self.expectation(forNotification: Zone5.authTokenChangedNotification, object: z5, handler: nil)
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "1234", refresh: "zxc", tokenExp: 4 as Milliseconds, username: "newuser"))
		wait(for: [expectation], timeout: 1)
		
		XCTAssertEqual("newuser", z5.accessToken?.username)
		XCTAssertEqual("1234", z5.accessToken?.rawValue)
	}
	
	func testAccessTokenCalculateExpiry() {
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "xcv", refresh: "23", expiresIn: 3))
		XCTAssertNotNil(z5.accessToken?.tokenExp)
		let tokenExp = z5.accessToken?.tokenExp
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "xcv", refresh: "23", expiresIn: 30))
		XCTAssertNotNil(z5.accessToken?.tokenExp)
		XCTAssertNotEqual(tokenExp, z5.accessToken?.tokenExp)
		XCTAssertTrue(z5.accessToken!.tokenExp! > Date().milliseconds)
		
		z5.configure(for: URL(string: "http://test")!, accessToken: OAuthToken(token: "xcv", refresh: "23", expiresAt: Date(), username: ""))
		XCTAssertNotNil(z5.accessToken?.expiresIn)
		XCTAssertTrue(z5.accessToken!.expiresIn! <= 0.1) // 0.1 for double rounding errors
	}
}
