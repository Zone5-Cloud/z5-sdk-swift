//
//  SearchResultTests.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 11/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class SearchResultTests: XCTestCase {

	func testDecodeResultsWithoutResult() throws {
		let result = try decode(
			json: "{\"cnt\": 10, \"offset\": 0}",
			as: SearchResult<UserWorkoutResult>.self
		)

		XCTAssertEqual(result.total, 10)
		XCTAssertEqual(result.offset, 0)

		XCTAssertEqual(result.count, 0)

		XCTAssert(result.result.fields.isEmpty)
		XCTAssert(result.result.keys.isEmpty)
	}

	func testDecodeResultsAsEmptyArray() throws {
		let result = try decode(
			json: "{\"result\": [], \"cnt\": 10, \"offset\": 0}",
			as: SearchResult<UserWorkoutResult>.self
		)

		XCTAssertEqual(result.total, 10)
		XCTAssertEqual(result.offset, 0)

		XCTAssertEqual(result.count, 0)

		XCTAssert(result.result.fields.isEmpty)
		XCTAssert(result.result.keys.isEmpty)
	}

	func testDecodeResultsAsArray() throws {
		let result = try decode(
			json: "{\"result\": [{\"id\": 12345, \"activity\": \"workouts\"}, {\"id\": 67890, \"activity\": \"files\"}], \"cnt\": 10, \"offset\": 0}",
			as: SearchResult<UserWorkoutResult>.self
		)

		XCTAssertEqual(result.total, 10)
		XCTAssertEqual(result.offset, 0)

		XCTAssertEqual(result.count, 2)
		XCTAssertEqual(result[0].id, 12345)
		XCTAssertEqual(result[0].activity, .workout)
		XCTAssertEqual(result[1].id, 67890)
		XCTAssertEqual(result[1].activity, .file)

		XCTAssert(result.result.fields.isEmpty)
		XCTAssert(result.result.keys.isEmpty)
	}

	func testDecodeResultsAsEmptyMappedResult() throws {
		let result = try decode(
			json: "{\"result\": {\"results\": [], \"fields\": {}, \"keys\": []}, \"cnt\": 10, \"offset\": 0}",
			as: SearchResult<UserWorkoutResult>.self
		)

		XCTAssertEqual(result.total, 10)
		XCTAssertEqual(result.offset, 0)

		XCTAssertEqual(result.count, 0)

		XCTAssert(result.result.fields.isEmpty)
		XCTAssert(result.result.keys.isEmpty)
	}

	func testDecodeResultsAsMappedResult() throws {
		let result = try decode(
			json: "{\"result\": {\"results\": [{\"id\": 12345, \"activity\": \"workouts\"}], \"fields\": {}, \"keys\": []}, \"cnt\": 10, \"offset\": 0}",
			as: SearchResult<UserWorkoutResult>.self
		)

		XCTAssertEqual(result.total, 10)
		XCTAssertEqual(result.offset, 0)

		XCTAssertEqual(result.count, 1)
		XCTAssertEqual(result[0].id, 12345)
		XCTAssertEqual(result[0].activity, .workout)

		XCTAssert(result.result.fields.isEmpty)
		XCTAssert(result.result.keys.isEmpty)
	}
	
	/// This is a response that I was receiving from the server that was breaking due to channels type enum being incomplete
	func testResult() {
		let resultString =  "{\"cnt\":2,\"offset\":0,\"result\":{\"fields\":{},\"results\":[{\"id\":135214,\"source\":\"file\",\"reviewMask\":0,\"user\":{\"id\":945,\"dob\":315532800000,\"firstname\":\"test\",\"lastname\":\"person\",\"isPremium\":true},\"review\":\"pending\",\"name\":\"1094d6ce-46f1-45c7-9294-e2c51cc4dfc7.fit\",\"fileId\":120398,\"activityId\":120398,\"activity\":\"files\",\"ts\":1598255381000,\"tz\":\"Australia/Sydney\",\"type\":\"ride\",\"equipment\":\"mtb\",\"workout\":\"training\",\"distance\":0.88,\"ascent\":0,\"channels\":[{\"name\":\"altitude\",\"type\":\"distancefixedmtrtomtrfeet\",\"min\":642.6,\"max\":643.4,\"avg\":642.99},{\"name\":\"altitude accuracy (m)\",\"type\":\"decimal2\",\"min\":2.0,\"max\":2.0,\"avg\":2.0},{\"name\":\"gps elevation (m)\",\"type\":\"decimal2\",\"min\":643.3,\"max\":643.3,\"avg\":643.3},{\"name\":\"gpsAccuracy\",\"type\":\"distancefixedmtrtomtrfeet\",\"min\":3.0,\"max\":37.0,\"avg\":8.32},{\"name\":\"smoothed elevation (m)\",\"type\":\"decimal2\",\"min\":642.79,\"max\":643.33,\"avg\":643.0},{\"name\":\"valid elevation\",\"type\":\"n\",\"min\":0.0,\"max\":1.0,\"avg\":0.98}],\"permissions\":[\"view3\",\"del\",\"view2\",\"edit2\",\"edit1\",\"view1\"],\"permissionMask\":183},{\"id\":135272,\"source\":\"file\",\"reviewMask\":0,\"user\":{\"id\":945,\"dob\":315532800000,\"firstname\":\"test\",\"lastname\":\"person\",\"isPremium\":true},\"review\":\"pending\",\"name\":\"da18cd73-88ed-4d6e-8585-6b2faffabe3f.fit\",\"fileId\":120456,\"activityId\":120456,\"activity\":\"files\",\"ts\":1598921469000,\"tz\":\"Australia/Sydney\",\"type\":\"ride\",\"equipment\":\"road\",\"workout\":\"training\",\"distance\":224.910004,\"ascent\":60,\"channels\":[{\"name\":\"altitude\",\"type\":\"distancefixedmtrtomtrfeet\",\"min\":581.8,\"max\":650.4,\"avg\":633.4},{\"name\":\"altitude accuracy (m)\",\"type\":\"decimal2\",\"min\":-1.0,\"max\":48.0,\"avg\":8.57},{\"name\":\"gps elevation (m)\",\"type\":\"decimal2\",\"min\":558.08,\"max\":648.4,\"avg\":633.39},{\"name\":\"gpsAccuracy\",\"type\":\"distancefixedmtrtomtrfeet\",\"min\":4.0,\"max\":48.0,\"avg\":10.48},{\"name\":\"gradient\",\"type\":\"grade\",\"min\":-322.03,\"max\":167.66,\"avg\":-23.51},{\"name\":\"smoothed elevation (m)\",\"type\":\"decimal2\",\"min\":610.36,\"max\":649.69,\"avg\":633.82},{\"name\":\"speed\",\"type\":\"speedms\",\"min\":0.01,\"max\":1.91,\"avg\":0.45},{\"name\":\"valid elevation\",\"type\":\"n\",\"min\":0.0,\"max\":1.0,\"avg\":0.99}],\"permissions\":[\"view3\",\"del\",\"view2\",\"edit2\",\"edit1\",\"view1\"],\"permissionMask\":183}],\"keys\":[]}}"
		let result = try? JSONDecoder().decode(SearchResult<UserWorkoutResult>.self, from: resultString.data(using: .utf8)!)
		XCTAssertNotNil(result)
		XCTAssertEqual(6, result?.result.results[0].channels?.count)
		XCTAssertEqual(8, result?.result.results[1].channels?.count)
		XCTAssertEqual(6, result?.result.results[0].permissions?.count)
	}

}
