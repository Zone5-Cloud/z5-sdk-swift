import Foundation

struct Request {

	let endpoint: RequestEndpoint

	let method: Zone5.Method

	let body: RequestBody?
    
    let headers: [String: String]?
	
	let queryParams: URLEncodedBody?
	
	let isZone5Endpoint: Bool

	init(endpoint: RequestEndpoint, method: Zone5.Method, headers: [String: String]? = nil, queryParams: URLEncodedBody? = nil, body: RequestBody? = nil) {
		self.endpoint = endpoint
		self.method = method
        self.headers = headers
		self.queryParams = queryParams
		self.body = body
		self.isZone5Endpoint = endpoint is Zone5RequestEndpoint
	}

	func urlRequest(zone5: Zone5, taskType: URLSessionTaskType) throws -> URLRequest {
		guard let url = endpoint.url else { throw Zone5.Error.invalidParameters }
		
		var request = URLRequest(url: url).setMeta(key: .zone5, value: zone5).setMeta(key: .taskType, value: taskType).setMeta(key: .isZone5Endpoint, value: isZone5Endpoint)
		request.httpMethod = method.rawValue

		// mark if token auth is required for the request
		if endpoint.requiresAccessToken {
			request = request.setMeta(key: .requiresAccessToken, value: true)
		}
		
		// if there are queryParams, set them in the request. This is valid on all types.
		if let queryParams = queryParams {
			try request.url = url.addingQueryParams(queryParams)
		}
        
		// if there are headers, add it to the request
		if let headers = headers {
			for header in headers {
				request.addValue(header.value, forHTTPHeaderField: header.key)
			}
		}
        
		// process body of request
		switch method {
		case .get, .head, .trace:
			// no body allowed
			if let body = body {
				z5Log("\(method.rawValue) request for endpoint `\(endpoint)` has body content of type `\(type(of: body))`. Is this intended to be a POST request?")
				throw Zone5.Error.unexpectedRequestBody
			}

		default:
			// body is optional
			if let body = body {
				do {
					request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
					request.httpBody = try body.encodedData()
				}
				catch {
					z5Log("An error was thrown while encoding the request body: \(error)")
					throw Zone5.Error.failedEncodingRequestBody
				}
			}
		}
		
		return request
	}

	func urlRequest(toUpload fileURL: URL, zone5: Zone5) throws -> (URLRequest, Data) {
		var request = try urlRequest(zone5: zone5, taskType: .upload)
		
		request.httpBody = nil

		do {
			var multipart = MultipartEncodedBody()
			try multipart.appendPart(name: "filename", content: fileURL.lastPathComponent)
			try multipart.appendPart(name: "attachment", contentsOf: fileURL)

			if let body = body as? JSONEncodedBody {
				try multipart.appendPart(name: "json", content: body)
			}
			else if body != nil {
				throw Zone5.Error.unexpectedRequestBody
			}

			request.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
			
			return (request, try multipart.encodedData())
		}
		catch Zone5.Error.unexpectedRequestBody {
			throw Zone5.Error.unexpectedRequestBody
		}
		catch {
			throw Zone5.Error.failedEncodingRequestBody
		}
	}

}
