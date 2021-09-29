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
			URLEncodedBody(queryString: "booleanFalse=false&booleanTrue=true&email=test@gmail.com&email+=test+1@gmail.com&empty&floatingPoint=9876.54321&integer=1234567890&string=hello world&url=https://this.com")
		]

		let expectedString = "booleanFalse=false&booleanTrue=true&email=test@gmail.com&email%2B=test%2B1@gmail.com&empty&floatingPoint=9876.54321&integer=1234567890&string=hello%20world&url=https://this.com"
		let expectedData = expectedString.data(using: .utf8)

		for test in tests {
			let string = test.description
			XCTAssertEqual(string, expectedString)

			let data = try test.encodedData()
			XCTAssertEqual(data, expectedData)
			
			XCTAssertEqual("false", test.get("booleanFalse"))
			XCTAssertEqual("true", test.get("booleanTrue"))
			XCTAssertEqual("test@gmail.com", test.get("email"))
			XCTAssertEqual("test+1@gmail.com", test.get("email+"))
			XCTAssertEqual("9876.54321", test.get("floatingPoint"))
			XCTAssertEqual("1234567890", test.get("integer"))
			XCTAssertEqual("hello world", test.get("string"))
			XCTAssertEqual("https://this.com", test.get("url"))
		}
	}
	
	func testPut() {
		var body: URLEncodedBody = ["key1": 1, "key2": "value2"]
		body.put(name: "key3", value: 1.0)
		
		XCTAssertEqual("1", body.get("key1"))
		XCTAssertEqual("value2", body.get("key2"))
		XCTAssertEqual("1.0", body.get("key3"))
		
		XCTAssertEqual("key1=1&key2=value2&key3=1.0", body.description)
	}
}
