//
//  URLRequestDelegate.swift
//  Zone5
//
//  Created by Jean Hall on 11/12/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

/// Delegate class used for managing the various calls made by `URLSessionTask`s.
/// Only used by uploads and downloads. Data tasks use completion handler which automatically disables delegates.
final internal class URLRequestDelegate: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {

	let notificationCenter: NotificationCenter

	init(notificationCenter: NotificationCenter = .default) {
		self.notificationCenter = notificationCenter
	}

	// MARK: Delegate queue

	/// Operation queue subclass that provides the defaults we like for our `URLSession` instances.
	/// - Note: The delegate queue provided to a `URLSession` is used regardless of whether a custom delegate is
	/// 	provided actually provided: completion handlers are called on the provided delegate queue.
	final internal class OperationQueue: Foundation.OperationQueue {

		override init() {
			super.init()
			qualityOfService = .userInitiated // Default operation queues have a QoS of `.utility` which can result in poor performance.
			maxConcurrentOperationCount = 1 // Operation queues for URLSessions must be serial.
		}

	}

	// MARK: Notifications posted by this delegate

	internal static let uploadProgressNotification = Notification.Name("URLRequestDelegate.uploadProgressNotification")

	internal static let uploadCompleteNotification = Notification.Name("URLRequestDelegate.uploadCompleteNotification")

	internal static let downloadProgressNotification = Notification.Name("URLRequestDelegate.downloadProgressNotification")

	internal static let downloadCompleteNotification = Notification.Name("URLRequestDelegate.downloadCompleteNotification")

	// MARK: URL session delegate methods

	private var receivedData: [URLSessionUploadTask: NSMutableData] = [:]

	/// URLSessionTaskDelegate: upload progress
	func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
		guard let uploadTask = task as? URLSessionUploadTask else { return }

		notificationCenter.post(name: URLRequestDelegate.uploadProgressNotification, object: uploadTask, userInfo: [
			"bytesSent": bytesSent,
			"totalBytesSent": totalBytesSent,
			"totalBytesExpectedToSend": totalBytesExpectedToSend,
		])
	}

	/// URLSessionDataDelegate: data response
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		guard let uploadTask = dataTask as? URLSessionUploadTask else { return }

		if let mutableData = receivedData[uploadTask] {
			mutableData.append(data)
		}
		else {
			receivedData[uploadTask] = NSMutableData(data: data)
		}
	}

	/// URLSessionDownloadDelegate: download progress
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		notificationCenter.post(name: URLRequestDelegate.downloadProgressNotification, object: downloadTask, userInfo: [
			"bytesWritten": bytesWritten,
			"totalBytesWritten" : totalBytesWritten,
			"totalBytesExpectedToWrite" : totalBytesExpectedToWrite
		])
	}

	/// URLSessionDownloadDelegate: download complete
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		var userInfo: [String: Any] = ["location": location]

		if let response = downloadTask.response {
			userInfo["response"] = response
		}

		notificationCenter.post(name: URLRequestDelegate.downloadCompleteNotification, object: downloadTask, userInfo: userInfo)
	}

	/// URLSessionTaskDelegate: task complete
	/// - Note: This method is called both when the task fails _and_ when it succeeds. As such, it is unnecessary to post
	/// the download completion notification from this method, as doing so will cause it to be posted twice.
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
		var userInfo: [String: Any] = [:]

		if let error = error {
			userInfo["error"] = error
		}

		if let response = task.response {
			userInfo["response"] = response
		}

		if let uploadTask = task as? URLSessionUploadTask {
			if let mutableData = receivedData.removeValue(forKey: uploadTask) {
				userInfo["data"] = Data(mutableData)
			}

			notificationCenter.post(name: URLRequestDelegate.uploadCompleteNotification, object: uploadTask, userInfo: userInfo)
		}
		else if let downloadTask = task as? URLSessionDownloadTask, error != nil {
			// It is only necessary to post the notification for downloads if the given `error` is non-null, as
			// `urlSession(_:downloadTask:didFinishDownloadingTo:)` is called when a download succeeds.
			notificationCenter.post(name: URLRequestDelegate.downloadCompleteNotification, object: downloadTask, userInfo: userInfo)
		}
	}

}
