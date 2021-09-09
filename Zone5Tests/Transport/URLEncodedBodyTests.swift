import XCTest
@testable import Zone5

final class URLEncodedBodyTests: XCTestCase {

	func testLiterals() throws {
		let tests: [URLEncodedBody] = [
			[ // Dictionary literal
				"booleanFalse": false,
				"booleanTrue": true,
				"email": "test@gmail.com",
				"email+": "test+1@gmail.com",
				"empty": nil,
				"floatingPoint": 9876.54321,
				"integer": 1234567890,
				"string": "hello world",
				"url" : "https://this.com"
			],
			[ // Array literal
				URLQueryItem(name: "booleanFalse", value: "false"),
				URLQueryItem(name: "booleanTrue", value: "true"),
				URLQueryItem(name: "email", value: "test@gmail.com"),
				URLQueryItem(name: "email+", value: "test+1@gmail.com"),
				URLQueryItem(name: "empty", value: nil),
				URLQueryItem(name: "floatingPoint", value: "9876.54321"),
				URLQueryItem(name: "integer", value: "1234567890"),
				URLQueryItem(name: "string", value: "hello world"),
				URLQueryItem(name: "url", value: "https://this.com")
			],
		]

		let expectedString = "booleanFalse=false&booleanTrue=true&email=test@gmail.com&email%2B=test%2B1@gmail.com&empty&floatingPoint=9876.54321&integer=1234567890&string=hello%20world&url=https://this.com"
		let expectedData = expectedString.data(using: .utf8)

		for test in tests {
			let string = test.description
			XCTAssertEqual(string, expectedString)

			let data = try test.encodedData()
			XCTAssertEqual(data, expectedData)
		}
	}
}
