//
//  OAuthTokenTests.swift
//  Zone5Tests
//
//  Created by Jean Hall on 28/9/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import XCTest
import Zone5

class OAuthTokenTests: XCTestCase {

    func testOAuthInitDate() throws {
		let date = Date() + 600
		let token = OAuthToken(token: "123", refresh: "zxc", expiresAt: date, username: "user@gmail.com")
		XCTAssertEqual(token.tokenExp, date.milliseconds)
		XCTAssertEqual(token.expiresIn!, 600, accuracy: 2) // allow accuracy because expiresIn is calculated from now so needs to accomodate test running time
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.5) // expiresAt is a calculated field, check calculation, allow a small rounding error
		XCTAssertEqual(token.username, "user@gmail.com")
    }

	func testOAuthInitMilli() throws {
		let date = Date() + 600
		let token = OAuthToken(token: "123", refresh: "zxc", tokenExp: date.milliseconds, username: "user@gmail.com")
		XCTAssertEqual(token.tokenExp, date.milliseconds)
		XCTAssertEqual(token.expiresIn!, 600, accuracy: 2) // allow accuracy because expiresIn is calculated from now so needs to accomodate test running time
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.5) // expiresAt is a calculated field, check calculation, allow a small rounding error
		XCTAssertEqual(token.username, "user@gmail.com")
	}
	
	func testOAuthDecodeFromServer() throws {
		// this is what tokens look like from the server
		let json = "{\"access_token\":\"testtoken\", \"refresh_token\": \"test refresh\", \"expires_in\":600}".data(using: .utf8)!;
		
		let date = Date() + 600
		let token = try JSONDecoder().decode(OAuthToken.self, from: json)
		XCTAssertEqual(token.accessToken, "testtoken")
		XCTAssertEqual(token.refreshToken, "test refresh")
		XCTAssertEqual(token.tokenExp!, date.milliseconds, accuracy: 1000) // allow for unit test execution time
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1) // allow test execution time
		XCTAssertEqual(token.expiresIn!, 600, accuracy: 1)
		XCTAssertNil(token.username)
	}
	
	func testOAuthDecodeFromServerLegacy() throws {
		// this is what legacy tokens look like from the server
		let json = "{\"access_token\":\"testtoken\", \"expires_in\":600}".data(using: .utf8)!;
		
		let date = Date() + 600
		let token = try JSONDecoder().decode(OAuthToken.self, from: json)
		XCTAssertEqual(token.accessToken, "testtoken")
		XCTAssertNil(token.refreshToken)
		XCTAssertEqual(token.tokenExp!, date.milliseconds, accuracy: 1000) // allow for unit test execution time
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1) // allow test execution time
		XCTAssertEqual(token.expiresIn!, 600, accuracy: 1)
		XCTAssertNil(token.username)
	}
	
	func testOAuthDecodeAdHocToken() throws {
		let json = "{\"access_token\":\"testtoken\",\"scope\":\"uploadactivity,routes\",\"expires_in\":2591999}".data(using: .utf8)!
		
		let date = Date() + 2591999
		let token = try JSONDecoder().decode(OAuthToken.self, from: json)
		XCTAssertEqual(token.accessToken, "testtoken")
		XCTAssertNil(token.refreshToken)
		XCTAssertEqual(token.tokenExp!, date.milliseconds, accuracy: 1000) // allow for unit test execution time
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1) // allow test execution time
		XCTAssertEqual(token.expiresIn!, 2591999, accuracy: 1)
		XCTAssertNil(token.username)
	}
	
	func testOAuthSaved() throws {
		let json = "{\"access_token\":\"testtoken\", \"refresh_token\": \"test refresh\", \"token_exp\":60000000, \"username\":\"test@user.com\"}".data(using: .utf8)!;
		
		let token = try JSONDecoder().decode(OAuthToken.self, from: json)
		XCTAssertEqual(token.accessToken, "testtoken")
		XCTAssertEqual(token.refreshToken, "test refresh")
		XCTAssertEqual(token.tokenExp!, 60000000)
		XCTAssertEqual(token.expiresAt!.timeIntervalSince1970, 60000) // allow test execution time
		XCTAssertTrue(token.expiresIn! < 0)
		XCTAssertEqual(token.username, "test@user.com")
	}
}
