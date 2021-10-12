import Foundation
import UIKit

final internal class HTTPClient {

	/// The parent instance of the `Zone5` SDK.
	internal weak var zone5: Zone5?

	/// The `URLSession` used to perform requests. It is configured to send all requests to the interceptor
	/// - Note: This is defined as a custom protocol to allow injection of a mock instance used in unit testing.
	private let urlSession: HTTPClientURLSession

	/// Initializes a new instance of the `HTTPClient` that uses the URLRequestInterceptor to process requests
	internal convenience init() {
		let configuration: URLSessionConfiguration = .default
		configuration.protocolClasses = [ URLRequestInterceptor.self ]

		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .userInitiated // Default operation queues have a QoS of `.utility` which can result in poor performance.
		operationQueue.maxConcurrentOperationCount = 1 // Operation queues for URLSessions must be serial.

		self.init(urlSession: URLSession(configuration: configuration, delegate: nil, delegateQueue: operationQueue))
	}

	/// Initializes a new instance of the `HTTPClient` with the given `URLSession`.
	/// This is used in unit tests to mock a `URLSession`.
	/// - Parameter urlSession: A custom `HTTPClientURLSession` instance to use for handling calls.
	/// - Note: For testing purposes _only_.
	internal init(urlSession: HTTPClientURLSession) {
		self.urlSession = urlSession
	}

	// MARK: Cache directories

	/// Cache directory used for storing uploads.
	private static let uploadsDirectory: URL = {
		let sharedURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		let uploadURL = sharedURL.appendingPathComponent("com.zone5ventures.Zone5SDK/uploads")
		try! FileManager.default.createDirectory(at: uploadURL, withIntermediateDirectories: true, attributes: nil)
		return uploadURL
	}()

	/// Cache directory used for storing downloads.
	internal static let downloadsDirectory: URL = {
		let sharedURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		let downloadURL = sharedURL.appendingPathComponent("com.zone5ventures.Zone5SDK/downloads")
		try! FileManager.default.createDirectory(at: downloadURL, withIntermediateDirectories: true, attributes: nil)
		return downloadURL
	}()

	// MARK: Rate-limiting

	internal static let dataQueue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .userInitiated
		operationQueue.maxConcurrentOperationCount = 4
		return operationQueue
	}()

	internal static let uploadQueue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .userInitiated
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	internal static let downloadQueue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.qualityOfService = .userInitiated
		operationQueue.maxConcurrentOperationCount = 1
		return operationQueue
	}()

	// MARK: Performing requests

	/// The decoder used to convert raw response data into a structure of the expected type.
	private let decoder = JSONDecoder()

	/// A closure that receives the result of a request.
	internal typealias CompletionHandler<T> = (_ result: Result<T, Zone5.Error>) -> Void

	/// Validates the SDK configuration, and then calls the given `block` closure, handling any thrown errors using the given `completion`.
	/// - Parameters:
	///   - completion: Closure called with errors that are thrown in the `block`.
	///   - block: The closure containing the work to perform. It receives a strong copy of the parent `Zone5` class, and the provided `completion`.
	/// - Throws: `Zone5.Error.invalidConfiguration` if the Zone5 instance has not been configured with a url
	/// - Note: If neither `clientID` nor `accessToken` is configured, the server will respond with an appropriate 401 error.
	private func execute<T>(
		on operationQueue: OperationQueue,
		with completion: @escaping CompletionHandler<T>,
		_ block: (_ zone5: Zone5, _ completion: @escaping CompletionHandler<T>) throws -> URLSessionTask
	) -> PendingRequest? {
		do {
			guard let zone5 = zone5, zone5.baseURL != nil else {
				throw Zone5.Error.invalidConfiguration
			}

			let operation = PendingRequestOperation()

			/// Wrap the provided completion handler in a dispatch call.
			/// Do this synchronously so that tasks performed afterwards (like deleting files) are handled correctly.
			let dispatchedCompletion: CompletionHandler<T> = { result in
				completion(result)

				operation.finish()
			}

			operation.task = try block(zone5, dispatchedCompletion)

			operationQueue.addOperation(operation)
			return operation
		}
		catch {
			if let error = error as? Zone5.Error {
				completion(.failure(error))
			}
			else {
				completion(.failure(.unknown))
			}

			return nil
		}
	}

	/// Perform a data task using the given `request`, calling the completion with the result.
	/// - Parameters:
	///   - request: A request that defines the endpoint, method and body used.
	///   - completion: Closure called with the result of the download. If successful, the response data is returned,
	internal func perform(
		_ request: Request,
		completion: @escaping CompletionHandler<(Data?, URLResponse)>
	) -> PendingRequest? {
		return execute(on: HTTPClient.dataQueue, with: completion) { zone5, completion in
			let urlRequest = try request.urlRequest(zone5: zone5, taskType: .data)

			let task = urlSession.dataTask(with: urlRequest) { data, response, error in
				if let error = error {
					completion(.failure(.transportFailure(error)))
				}
				else if let response = response {
					completion(.success((data, response)))
				}
				else {
					completion(.failure(.unknown))
				}
			}

			task.priority = URLSessionTask.highPriority
			return task
		}
	}

	/// Perform a data task using the given `request`, calling the completion with the result.
	/// - Parameters:
	///   - request: A request that defines the endpoint, method and body used.
	///   - keyDecodingStrategy: The strategy to use when decoding the response's keys. Defaults to `.useDefaultKeys`.
	///   - expectedType: The expected, `Decodable` type that is used to decode the response data.
	///   - completion: Closure called with the result of the download. If successful, the response data is returned,
	///   		decoded as the given `expectedType`, otherwise the error that was encountered.
	internal func perform<T: Decodable>(
		_ request: Request,
		keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
		expectedType: T.Type,
		completion: @escaping CompletionHandler<T>
	) -> PendingRequest? {
		return execute(on: HTTPClient.dataQueue, with: completion) { zone5, completion in
			let urlRequest = try request.urlRequest(zone5: zone5, taskType: .data)
			
			let decoder = self.decoder
            decoder.keyDecodingStrategy = keyDecodingStrategy
            
			let task = urlSession.dataTask(with: urlRequest) { data, response, error in
				if let error = error {
					completion(.failure(.transportFailure(error)))
				}
				else if let data = data {
					completion(decoder.decode(data, response: response, from: request, as: expectedType, debugLogging: zone5.debugLogging))
				}
				else {
					completion(.failure(.unknown))
				}
			}

			task.priority = URLSessionTask.highPriority
			return task
		}
	}
    
	/// Perform an upload task using the given `fileURL` and `request`, calling the completion with the result.
	///
	/// This method prepares a `MultipartEncodedBody` containing the contents of the file to be uploaded, caches it to
	/// disk, and then uses that as the source for the subsequent upload task, attaching the `request`s body as a part
	/// of the multipart data. As such, the request body is therefore expected to conform to `JSONEncodedBody`, and
	/// will result in an error if another body type is provided.
	/// - Parameters:
	///   - fileURL: The URL for the file to be uploaded.
	///   - request: A request that defines the endpoint, method and body used.
	///   - keyDecodingStrategy: The strategy to use when decoding the response's keys. Defaults to `.useDefaultKeys`.
	///   - expectedType: The expected, `Decodable` type that is used to decode the response data.
	///   - completion: Closure called with the result of the upload. If successful, the response data is returned,
	///   		decoded as the given `expectedType`, otherwise the error that was encountered.
	internal func upload<T: Decodable>(
		_ fileURL: URL,
		with request: Request,
		keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
		expectedType: T.Type,
		completion: @escaping CompletionHandler<T>
	) -> PendingRequest? {
		return execute(on: HTTPClient.uploadQueue, with: completion) { zone5, completion in
			var (urlRequest, multipartData) = try request.urlRequest(toUpload: fileURL, zone5: zone5)
			let cacheURL = HTTPClient.uploadsDirectory.appendingPathComponent("\(fileURL.lastPathComponent).\(UUID().uuidString).multipart")

			// save URL against the request (needed to create actual uploadTask in interceptor)
			urlRequest = urlRequest.setMeta(key: .fileURL, value: cacheURL)
			
			do {
				try multipartData.write(to: cacheURL)
			}
			catch {
				throw Zone5.Error.failedEncodingRequestBody
			}

			let decoder = self.decoder
            decoder.keyDecodingStrategy = keyDecodingStrategy
			
			return urlSession.uploadTask(with: urlRequest, fromFile: cacheURL) { data, response, error in
				defer { try? FileManager.default.removeItem(at: cacheURL) }

				if let error = error {
					completion(.failure(.transportFailure(error)))
				}
				else if let data = data {
					completion(decoder.decode(data, response: response, from: request, as: expectedType, debugLogging: zone5.debugLogging))
				}
				else {
					completion(.failure(.unknown))
				}
			}
		}
	}

	/// Perform a download task using the given `request`, calling the completion with the result.
	/// - Parameters:
	///   - request: A request that defines the endpoint, method and body used.
	///   - progress: Closure called periodically with the download's progress.
	///   - completion: Closure called with the result of the download. If successful, the location of the downloaded
	///			file on disk is returned, otherwise the error that was encountered.
	internal func download(
		_ request: Request,
		progress: ((_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void)? = nil,
		completion: @escaping CompletionHandler<URL>
	) -> PendingRequest? {
		return execute(on: HTTPClient.downloadQueue, with: completion) { zone5, completion in
			var urlRequest = try request.urlRequest(zone5: zone5, taskType: .download)
			
			if let progress = progress {
				urlRequest = urlRequest.setMeta(key: .progressHandler, value: progress)
			}

			let decoder = self.decoder
			decoder.keyDecodingStrategy = .useDefaultKeys
			
			// create with no completion handler. This will force delegate to be used so that we can capture progress
			return urlSession.downloadTask(with: urlRequest) { location, response, error in
				if let error = error {
					completion(.failure(.transportFailure(error)))
					return
				}
				
				guard let response = response as? HTTPURLResponse, let filename = response.suggestedFilename else {
					completion(.failure(.unknown))
					return
				}
				
				let cacheURL = HTTPClient.downloadsDirectory.appendingPathComponent(filename)
				
				if (200..<400).contains(response.statusCode) {
					if let resources = try? cacheURL.resourceValues(forKeys:[.fileSizeKey]), resources.fileSize! > 0 {
						// success case - the file is the download
						completion(.success(cacheURL))
						try? FileManager.default.removeItem(at: cacheURL)
						return
					} else {
						// supposed to be success but can't find file
						completion(.failure(.unknown))
						return
					}
				} else if let resources = try? cacheURL.resourceValues(forKeys:[.fileSizeKey]), resources.fileSize! > 0, let data = try? Data(contentsOf: cacheURL) {
					// server error case - the file is an error description
					completion(decoder.decode(data, response: response, from: request, as: URL.self, debugLogging: zone5.debugLogging))
					return
				} else {
					// error case - no file to decode - use default error for statusCode
					let message = Zone5.Error.ServerMessage(message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode), statusCode: response.statusCode)
					completion(.failure(.serverError(message)))
					return
				}
			}
		}
	}

}

extension JSONDecoder {

	func decode<T: Decodable>(_ data: Data, response: URLResponse?, from request: Request, as expectedType: T.Type, debugLogging: Bool = false) -> Result<T, Zone5.Error> {
		defer {
			if debugLogging {
				// don't unnecessarily construct log lines unless debugLogging is explicitly set
				var debugMessage = ""
				if let requestData = try? request.body?.encodedData(), let requestString = String(data: requestData, encoding: .utf8) {
					debugMessage += "\n\t- Request to \(request.endpoint.uri): \(requestString)"
				}
				if let responseString = String(data: data, encoding: .utf8) {
					debugMessage += "\n\t- Response: \(responseString)"
				}
				z5DebugLog(debugMessage)
			}
		}

		if let httpResponse = response as? HTTPURLResponse {
			guard (200..<400).contains(httpResponse.statusCode) else {
				z5DebugLog("Server responded with status code of \(httpResponse.statusCode) to \(request.endpoint.uri). (headers were \(request.headers ?? [:]))")

				do {
					var decodedMessage = try decode(Zone5.Error.ServerMessage.self, from: data)
					decodedMessage.statusCode = httpResponse.statusCode

					return .failure(.serverError(decodedMessage))
				}
				catch {
					let serverError = Zone5.Error.ServerMessage(message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode), statusCode: httpResponse.statusCode)
					return .failure(.serverError(serverError))
				}
			}
		}

		do {
			// Attempt to decode and return the `data` as the `expectedType` using our decoder
			if expectedType == Zone5.VoidReply.self {
				// special handling required for Void types. Enforce enpty data. Create NoReply object.
				if data.count > 0 {
					z5Log("Failed to decode server response as `\(expectedType)`. Error: Non Void response")
					return .failure(.failedDecodingResponse(Zone5.Error.unknown))
				} else {
					return .success(Zone5.VoidReply() as! T)
				}
			}

			let decodedValue: T
			if #available(iOS 13.0, *) {
				// from iOS 13 fragments are correctly decoded
				//print(String(bytes: data, encoding: .utf8))
				decodedValue = try decode(expectedType, from: data)
			}
			else if expectedType == Bool.self || expectedType == String.self {
				// prior to iOS 13 top level fragments cannot be decoded with JSONDecoder.
				// If we know that we are a fragment, decode fragement
				let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
				decodedValue = jsonObject as! T
			} else {
				// prior to iOS 13 top level fragments cannot be decoded with JSONDecoder.
				// If we do not know that we are a fragement, attempt normal decode and fall back to fragment
				do {
					decodedValue = try decode(expectedType, from: data)
				}
				catch {
					let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
					if let value = jsonObject as? T {
						decodedValue = value
					} else if let value = jsonObject as? Zone5.Error.ServerMessage {
						z5Log("Failed to decode server response as `\(expectedType)`. Error: \(error)")
						return .failure(.serverError(value))
					} else {
						throw error
					}
				}
			}

			z5DebugLog("Successfully decoded server response from \(response?.url?.absoluteString ?? "") as `\(expectedType)`.")

			return .success(decodedValue)
		}
		catch {
			let originalError = error

			z5Log("Failed to decode server response as `\(expectedType)`. Error: \(originalError)")

			do {
				// Decoding as `expectedType` failed, so lets try to decode as a `ServerMessage` instead, in the hopes
				// that the server responded with a legitimate error.
				let decodedMessage = try decode(Zone5.Error.ServerMessage.self, from: data)

				return .failure(.serverError(decodedMessage))
			}
			catch {
				// maybe it is a raw (non json compliant) string. Try decoding it ourselves
				if expectedType == String.self, let decodedValue = String(data: data, encoding: .utf8) {
					return .success(decodedValue as! T)
				}

				// Decoding as a `ServerMessage` also failed, so we should pass on the original error.
				// Getting this far typically means there's a problem in the SDK.
				return .failure(.failedDecodingResponse(originalError))
			}
		}
	}


}

internal protocol HTTPClientURLSession: AnyObject {

	func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask

	func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask

	func downloadTask(with: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask

}

extension URLSession: HTTPClientURLSession { }
