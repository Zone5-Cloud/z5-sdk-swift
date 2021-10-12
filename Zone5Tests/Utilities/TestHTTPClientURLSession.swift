//
//  TestHTTPClientURLSession.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 7/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import Foundation
@testable import Zone5

class TestHTTPClientURLSession: HTTPClientURLSession {
	
	enum Result<Success> {
		case success(Success)
		case message(String, statusCode: Int)
		case error(Error)
		case failure(String, statusCode: Int)
	}

	// MARK: Data tasks

	/// - Returns: Result enumeration containing either a JSON string or an error.
	var dataTaskHandler: ((_ request: URLRequest) -> Result<String>)?

	func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		return DataTask {
			let result = self.dataTaskHandler?(URLRequestInterceptor.decorate(request: request))

			switch result {
			case .none:
				fatalError("Expected a `dataTaskHandler` to be defined.")
			case .message(let message, let statusCode):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				let json = "{\"message\": \"\(message)\"}"
				completionHandler(json.data(using: .utf8), response, nil)
			case .failure(let json, let statusCode):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(json.data(using: .utf8), response, nil)
			case .error(let error):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(nil, response!, error)
			case .success(let json):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(json.data(using: .utf8), response, nil)
			}
		}
	}

	final class DataTask: URLSessionDataTask {

		let onResume: () -> Void

		init(onResume: @escaping () -> Void) {
			self.onResume = onResume
		}

		override func resume() {
			self.onResume()
		}

	}

	// MARK: Upload tasks

	/// - Returns: Result enumeration containing either a JSON string or an error.
	var uploadTaskHandler: ((_ request: URLRequest, _ fileURL: URL) -> Result<String>)?

	func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
		return UploadTask {
			let result = self.uploadTaskHandler?(URLRequestInterceptor.decorate(request: request), fileURL)

			switch result {
			case .none:
				fatalError("Expected an `uploadTaskHandler` to be defined.")
			case .message(let message, let statusCode):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				let json = "{\"message\": \"\(message)\"}"
				completionHandler(json.data(using: .utf8), response, nil)
			case .failure(let json, let statusCode):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(json.data(using: .utf8), response, nil)
			case .error(let error):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(nil, response!, error)
			case .success(let json):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(json.data(using: .utf8), response, nil)
			}
		}
	}

	final class UploadTask: URLSessionUploadTask {

		let onResume: () -> Void

		init(onResume: @escaping () -> Void) {
			self.onResume = onResume
		}

		override func resume() {
			self.onResume()
		}

	}

	// MARK: Download tasks

	/// - Returns: Result enumeration containing either a file URL or an error.
	var downloadTaskHandler: ((_ request: URLRequest) -> Result<URL>)?

	func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
		return DownloadTask {
			let result = self.downloadTaskHandler?(URLRequestInterceptor.decorate(request: request))

			switch result {
			case .none:
				fatalError("Expected an `downloadTaskHandler` to be defined.")
			case .message(let message, let statusCode):
				
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])!
				
				let tempURL = HTTPClient.downloadsDirectory.appendingPathComponent(response.suggestedFilename!)
				let json = "{\"message\": \"\(message)\"}"
				try! json.write(to: tempURL, atomically: true, encoding: .utf8)


				completionHandler(tempURL, response, nil)
			case .failure(let json, let statusCode):
				let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("dataResponse.tmp")
				try! json.write(to: tempURL, atomically: true, encoding: .utf8)
				let response = HTTPURLResponse.init(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(tempURL, response!, nil)
			case .error(let error):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Type": "application/json",
				])

				completionHandler(nil, response!, error)
			case .success(let url):
				let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
					"Content-Disposition": "attachment; filename=\"\(url.lastPathComponent)\"",
					"Content-Type": "application/octet-stream",
				])!
				
				let copy = HTTPClient.downloadsDirectory.appendingPathComponent(response.suggestedFilename!)
				try? FileManager.default.copyItem(at: url, to: copy)

				completionHandler(url, response, nil)
			}
		}
	}

	final class DownloadTask: URLSessionDownloadTask {

		let onResume: () -> Void

		init(onResume: @escaping () -> Void) {
			self.onResume = onResume
		}

		override func resume() {
			self.onResume()
		}

	}

}
