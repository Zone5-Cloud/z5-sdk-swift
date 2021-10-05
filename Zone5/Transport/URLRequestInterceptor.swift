//
//  URLRequestInterceptor.swift
//  Zone5
//
//  Created by Jean Hall on 17/11/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

internal class URLRequestInterceptor: URLProtocol {
	
	// synchronize auto refresh so that only 1 request at a time can issue a refresh
	static private let refreshDispatchQueue = DispatchQueue(label: "URLRequestInterceptor.refreshDispatchQueue")
	static private let refreshDispatchSemaphore = DispatchSemaphore(value: 1) // allow 1 through at a time
	
	private let session: URLSession
	private var currentTask: URLSessionTask? = nil
	
	override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
		// Assign the session based on the type of task handling the request. Each type needs to be handled differently,
		// to ensure that uploads may complete if the app is backgrounded, and that file transfers don't hog bandwidth.
		switch request.taskType {
		case .data:
			session = Zone5HTTPClient.interceptorDataSession
		case .download:
			session = Zone5HTTPClient.interceptorDownloadSession
		case .upload:
			session = Zone5HTTPClient.interceptorUploadSession
		}
		
		super.init(request: request, cachedResponse: cachedResponse, client: client)
	}
	
	/// intercept all requests, alter them and send them out the local shared session
	override class func canInit(with task: URLSessionTask) -> Bool {
		return true
	}
	
	/// intercept all requests, alter them and send them out the local shared session
	override class func canInit(with request: URLRequest) -> Bool {
		return true
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}

	override func startLoading() {
        // if we have a Cognito token with an expiry and this request requires auth token, check the expiry
		if let requiresAccessToken = request.getMeta(key: .requiresAccessToken) as? Bool, requiresAccessToken,
           let zone5 = request.getMeta(key: .zone5) as? Zone5,
		   let token = zone5.accessToken, token.requiresRefresh {
			// our token expires in less than 30 seconds. Do a refresh before sending the request
			// do these refresh requests synchronously so only one executes at a time and others wait for first refresh to complete - at which point duplicate refresh not necessary
			URLRequestInterceptor.refreshDispatchQueue.async {
				URLRequestInterceptor.refreshDispatchSemaphore.wait() // should let first 1 through
				// recheck TTL once inside mutex block, cos it might have been updated by another refresh while we were waiting for mutex
				if let token = zone5.accessToken, token.requiresRefresh {
					zone5.oAuth.refreshAccessToken() { result in
						// note that refresh does not require auth so it will not cyclicly enter this path
						URLRequestInterceptor.refreshDispatchSemaphore.signal()
						self.decorateAndSendRequest()
					}
				} else {
					// the refresh must've been performed while we were waiting for mutex. Signal and sendRequest immediately
					URLRequestInterceptor.refreshDispatchSemaphore.signal()
					self.decorateAndSendRequest()
				}
			}
			return
		} else {
			// token is not about to expire, has no refresh token, or we don't need auth. Send request immediately
			decorateAndSendRequest()
		}
	}
	
	override func stopLoading() {
		self.currentTask?.cancel()
	}
	
	private func onComplete(data: Data?, response: URLResponse?, error: Error?) {
		if let response = response {
			self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
		}
		
		if let data = data {
			self.client?.urlProtocol(self, didLoad: data)
		}
		 
		if let error = error {
			self.client?.urlProtocol(self, didFailWithError: error)
		}
		
		self.client?.urlProtocolDidFinishLoading(self)
	}
	
	/// call decorate(...) and then sendRequest(...)
	private func decorateAndSendRequest() {
		// decorate headers. This needs to be after the refresh code as the token may change
		let request = URLRequestInterceptor.decorate(request: self.request)
		
        z5DebugLog("Decorated for \(request.url?.absoluteString ?? ""): \(request.allHTTPHeaderFields ?? [:])")
		
		// send
		sendRequest(request)
	}
	
	/// decorate the request with headers, based on the given Zone5 configuraion
	/// - Parameters:
	///   - request: The request being decorated
	///	  - with: The Zone5 instance to decorate the request with
	class func decorate(request: URLRequest) -> URLRequest {
		let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
		let zone5 = request.getMeta(key: .zone5) as? Zone5
		let isZone5Endpoint = request.getMeta(key: .isZone5Endpoint) as? Bool ?? true
		
		// set user agent if configured
		if let agent = zone5?.userAgent, !agent.isEmpty {
			mutableRequest.setValue(agent, forHTTPHeaderField: Zone5HttpHeader.userAgent.rawValue)
		}
		
		// set legacy tp-nodecorate header
		if isZone5Endpoint {
			mutableRequest.setValue("true", forHTTPHeaderField: Zone5HttpHeader.tpNoDecorate.rawValue)
		}
		
		// Sign the request with the access token if required
		if let requiresAccessToken = request.getMeta(key: .requiresAccessToken) as? Bool, requiresAccessToken, let zone5 = zone5, let token = zone5.accessToken, !token.rawValue.isEmpty {
			mutableRequest.setValue("Bearer \(token.rawValue)", forHTTPHeaderField: Zone5HttpHeader.authorization.rawValue)
		}
		
		if isZone5Endpoint, let clientID = zone5?.clientID {
			mutableRequest.setValue(clientID, forHTTPHeaderField: Zone5HttpHeader.apiKey.rawValue)
		}
		
		if isZone5Endpoint, let clientSecret = zone5?.clientSecret {
			mutableRequest.setValue(clientSecret, forHTTPHeaderField: Zone5HttpHeader.apiSecret.rawValue)
		}
		
		return mutableRequest as URLRequest
	}
	
	/// We have finished with intercepting this request. Send the request for real with the real url session
	internal func sendRequest(_ request: URLRequest) {
		let url = request.getMeta(key: .fileURL) as? URL
		let type = request.taskType
		let onProgress = request.getMeta(key: .progressHandler) as? (_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void
		
		// now we are finished with the request meta. Clear it before we continue
		let request = request.clearMeta()
		let currentTask: URLSessionTask
		
		switch type {
		case .data:
			currentTask = session.dataTask(with: request, completionHandler: onComplete)

		case .upload:
			guard let url = url else {
				onComplete(data: nil, response: nil, error: Zone5.Error.invalidParameters)

				return
			}

			currentTask = session.uploadTask(with: request, fromFile: url)

			var completionObserver : NSObjectProtocol? = nil
			completionObserver = NotificationCenter.default.addObserver(forName: URLRequestDelegate.uploadCompleteNotification, object: currentTask, queue: nil) { [ weak self ] notification in
				// remove observers.
				if let completionObserver = completionObserver {
					NotificationCenter.default.removeObserver(completionObserver, name: URLRequestDelegate.downloadCompleteNotification, object: currentTask)
				}

				let data = notification.userInfo?["data"] as? Data
				let response = notification.userInfo?["response"] as? URLResponse
				let error = notification.userInfo?["error"] as? Error

				self?.onComplete(data: data, response: response, error: error)
			}

		case .download:
			currentTask = session.downloadTask(with: request)
		
			let progressObserver: NSObjectProtocol? = NotificationCenter.default.addObserver(forName: URLRequestDelegate.downloadProgressNotification, object: currentTask, queue: nil) { notification in
				if let bytesWritten = notification.userInfo?["bytesWritten"] as? Int64,
				   let totalBytesWritten = notification.userInfo?["totalBytesWritten"] as? Int64,
				   let totalBytesExpectedToWrite = notification.userInfo?["totalBytesExpectedToWrite"] as? Int64 {
					onProgress?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
				}
			}
			
			var completionObserver : NSObjectProtocol? = nil
			completionObserver = NotificationCenter.default.addObserver(forName: URLRequestDelegate.downloadCompleteNotification, object: currentTask, queue: nil) { [ weak self ] notification in
				// remove observers.
				if let progressObserver = progressObserver {
					NotificationCenter.default.removeObserver(progressObserver, name: URLRequestDelegate.downloadProgressNotification, object: currentTask)
				}
				if let completionObserver = completionObserver {
					NotificationCenter.default.removeObserver(completionObserver, name: URLRequestDelegate.downloadCompleteNotification, object: currentTask)
				}
				
				let response = notification.userInfo?["response"] as? URLResponse
				let error = notification.userInfo?["error"] as? Error

				if let location = notification.userInfo?["location"] as? URL, let filename = (response as? HTTPURLResponse)?.suggestedFilename {
					// attempt to copy this file to another location because it will be deleted on return of this function
					let cacheURL = Zone5HTTPClient.downloadsDirectory.appendingPathComponent(filename)
					try? FileManager.default.removeItem(at: cacheURL)
					try? FileManager.default.copyItem(at: location, to: cacheURL)
				}
				
				self?.onComplete(data: nil, response: response, error: error)
			}
		}

		self.currentTask = currentTask
		currentTask.resume()
	}
	
	/// Decode the Cognito token to get the username out of it. It is required for the cognito refresh
	/// note: We are now saving the username with the OAuthToken so we don't need to pull it out of
	/// the cognito token. But if for some reason it is missing in the OAuthToken then we can try here
	internal func extractUsername(from jwt: String) -> String? {
		
		enum DecodeErrors: Error {
			case badToken
			case other
		}
		
		func base64Decode(_ base64: String) throws -> Data {
			let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
			guard let decoded = Data(base64Encoded: padded) else {
				throw DecodeErrors.badToken
			}
			return decoded
		}
		
		func decodeJWTPart(_ value: String) throws -> [String: Any] {
			let bodyData = try base64Decode(value)
			let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
			guard let payload = json as? [String: Any] else {
				throw DecodeErrors.other
			}
			return payload
		}
		
		let segments = jwt.components(separatedBy: ".")
		let part = segments.count > 1 ? (try? decodeJWTPart(segments[1])) ?? [:] : [:]
		return part["email"] as? String
	}
	
}

extension URLRequest {
	/// Creates a mutable copy of self, adds meta data to it, and returns the new URLRequest struct
	/// note URLRequest is a struct and is passed by value so the result of this must be assigned to the calling variable
	internal func setMeta(key: URLProtocolProperty, value: Any) -> URLRequest {
		let mutatingRequest = (self as NSURLRequest).mutableCopy() as! NSMutableURLRequest
		URLProtocol.setProperty(value, forKey: key.rawValue, in: mutatingRequest)
		return mutatingRequest as URLRequest
	}
	
	internal func getMeta(key: URLProtocolProperty) -> Any? {
		return URLProtocol.property(forKey: key.rawValue, in: self)
	}
	
	internal var taskType: URLSessionTaskType {
		return getMeta(key: .taskType) as? URLSessionTaskType ?? .data
	}
	
	internal func clearMeta() -> URLRequest{
		let mutatingRequest = (self as NSURLRequest).mutableCopy() as! NSMutableURLRequest
		for property in URLProtocolProperty.allCases {
			URLProtocol.removeProperty(forKey: property.rawValue, in: mutatingRequest)
		}
		return mutatingRequest as URLRequest
	}
}

