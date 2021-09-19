import Foundation

/// Parameters that may be encoded as a URL query string, i.e. `key=value&otherKey=otherValue`.
///
/// This structure can be used all request types. For requests that can take a request body (i.e. POST), the output of
/// the `encodedData()` method is used. In instances where this is not the case, the `description` is appended to the
/// endpoint URL as a query string.
public struct URLEncodedBody: RequestBody, CustomStringConvertible, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {

	private(set) var queryItems: [URLQueryItem]

	init(queryItems: [URLQueryItem]) {
		self.queryItems = queryItems
	}
	
	public init(queryString: String) {
		var queryItems: [URLQueryItem] = []

		for query in queryString.split(separator: "&") {
			let keyValue = query.split(separator: "=", maxSplits: 1)
			if keyValue.count == 2 {
				queryItems.append(URLQueryItem(name: String(keyValue[0]), value: String(keyValue[1])))
			} else if keyValue.count == 1 {
				queryItems.append(URLQueryItem(name: String(keyValue[0]), value: nil))
			}
		}

		self.init(queryItems: queryItems)
	}
	
	public func get(_ name: String) -> String? {
		return queryItems.first(where: {$0.name == name})?.value
	}

	// MARK Custom string convertible

    public var description: String {
		return queryItems.map { item in
			var allowedCharacters: CharacterSet = .urlQueryAllowed
			allowedCharacters.remove("+")
			
			guard let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
				return item.name
			}

			if let encodedValue = item.value?.addingPercentEncoding(withAllowedCharacters: allowedCharacters) {
				return String(format: "%@=%@", encodedName, encodedValue)
			}
			else {
				return String(format: "%@", encodedName)
			}
		}.joined(separator: "&")
	}

	// MARK: Expressible by array literal

	public init(arrayLiteral elements: URLQueryItem...) {
		self.init(queryItems: elements)
	}
	
	// MARK: Expressibly by dictionary literal

    public init(dictionaryLiteral elements: (String, CustomStringConvertible?)...) {
        var queryItems: [URLQueryItem] = []

		for (key, value) in elements {
			queryItems.append(URLQueryItem(name: key, value: value?.description))
		}

		self.init(queryItems: queryItems.sorted { $0.name < $1.name })
	}

	// MARK: Request parameters

    public let contentType = "application/x-www-form-urlencoded"

    public func encodedData() throws -> Data {
		guard let data = description.data(using: .utf8) else {
			throw Error.requiresLossyConversion
		}

		return data
	}

	enum Error: Swift.Error {
		case requiresLossyConversion
	}

}

extension URL {
	internal func addingQueryParams(_ query: URLEncodedBody) throws -> URL? {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			z5Log("Request URL could not be converted to URLComponents: \(self)")
			throw Zone5.Error.failedEncodingRequestBody
		}

		components.queryItems = query.queryItems
		// URLComponents does not encode "+". Need to do manually
		components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
		return components.url
	}
}
