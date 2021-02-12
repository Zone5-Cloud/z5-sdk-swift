//
//  MetricsViewTests.swift
//  Zone5
//
//  Created by Jean Hall on 14/4/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import XCTest
@testable import Zone5

class MetricsViewTests: XCTestCase {
	
	func testBikeMetrics() {
		let tests: [(token: AccessToken?, json: String, expectedResult: Result<MappedResult<UserWorkoutResult>, Zone5.Error>)] = [
			(
				token: nil,
				json: "n/a",
				expectedResult: .failure(authFailure)
			),
			(
				token: OAuthToken(rawValue: UUID().uuidString),
				json: "{\"fields\":{},\"results\":[{\"user\":{\"id\":175,\"firstname\":\"John\",\"lastname\":\"Smith\"},\"name\":\"Series\",\"count\":1,\"bike\":{\"uuid\":\"d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c\"},\"sum\":{\"training\":7031,\"distance\":54737.949219,\"ascent\":692},\"max\":{\"maxSpeed\":63.684002},\"wavg\":{\"avgSpeed\":28.501199}}],\"keys\":[\"id\"]}",
				expectedResult: .success {
					var result = MappedResult<UserWorkoutResult>()
					result.keys = ["id"]
					result.results = [ UserWorkoutResult() ]
					result.results[0].bike = UserWorkoutResultBike()
					result.results[0].bike?.uuid = "d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c"
					result.results[0].count = 1
					var max = UserWorkoutResult()
					max.maximumSpeed = 63.684002
					result.results[0].maximum = .indirect(max)
					result.results[0].name = "Series"
					result.results[0].user = User()
					result.results[0].user?.firstName = "John"
					result.results[0].user?.id = 175
					result.results[0].user?.lastName = "Smith"
					var sum = UserWorkoutResult()
					sum.ascent = 692
					sum.distance = 54737.949219
					sum.training = 7031
					result.results[0].sum = .indirect(sum)
					var wavg = UserWorkoutResult()
					wavg.averageSpeed = 28.501199
					result.results[0].weightedAverage = .indirect(wavg)
					return result
				}
			),
		]

		execute(with: tests) { client, _, urlSession, test in

			client.metrics.getBikeMetrics(ranges: [], fields: ["fields"], bikeUids: ["d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c"]) { result in
				switch (result, test.expectedResult) {
				case (.failure(let lhs), .failure(let rhs)):
					XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain)
					XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code)

				case (.success(let lhs), .success(let rhs)):
					XCTAssertEqual(lhs.keys, rhs.keys)
					XCTAssertEqual(lhs.results.count, rhs.results.count)
					XCTAssertEqual(lhs.results[0].bike?.uuid, rhs.results[0].bike?.uuid)
					XCTAssertEqual(lhs.results[0].maximum?.maximumSpeed, rhs.results[0].maximum?.maximumSpeed)
					XCTAssertEqual(lhs.results[0].weightedAverage?.averageSpeed, rhs.results[0].weightedAverage?.averageSpeed)
					XCTAssertEqual(lhs.results[0].sum?.distance, rhs.results[0].sum?.distance)
					XCTAssertEqual(lhs.results[0].sum?.training, rhs.results[0].sum?.training)
					XCTAssertEqual(lhs.results[0].sum?.ascent, rhs.results[0].sum?.ascent)
					XCTAssertEqual(lhs.results[0].sum?.ascent, 692)
				default:
					print(result, test.expectedResult)
					XCTFail()
				}
			}
		}
	}
}
