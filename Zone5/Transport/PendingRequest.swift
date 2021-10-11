//
//  PendingRequest.swift
//  Zone5
//
//  Created by Jean Hall on 7/5/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

public protocol PendingRequest: NSObjectProtocol {

	func cancel()
	
	var isComplete: Bool { get }
	
	var isCancelled: Bool { get }

}

internal class PendingRequestOperation: Operation, PendingRequest {

	/// The task being performed by the operation.
	/// - Note: The operation will not be considered ready if no task is assigned.
	internal var task: URLSessionTask? {
		willSet { willChangeValue(for: \.isReady) }
		didSet { didChangeValue(for: \.isReady) }
	}

	// MARK: Cancelling operations

	/// Starts the underlying `URLSessionTask` and marks the operation as executing.
	internal override func start() {
		guard isReady, let task = task else { return }

		willChangeValue(for: \.isExecuting)
		self._isExecuting = true
		didChangeValue(for: \.isFinished)

		task.resume()
	}

	/// Marks the operation as cancelled, and cancels the underlying `URLSessionTask` (if available).
	internal override func cancel() {
		task?.cancel()

		willChangeValue(for: \.isCancelled)
		_isCancelled = true
		didChangeValue(for: \.isCancelled)
	}

	/// Marks the operation as finished, allowing pending operations in the queue to start.
	internal func finish() {
		guard isReady else { return }

		willChangeValue(for: \.isExecuting)
		willChangeValue(for: \.isFinished)
		self._isExecuting = false
		self._isFinished = true
		didChangeValue(for: \.isExecuting)
		didChangeValue(for: \.isFinished)
	}

	// MARK: Getting the operation status

	private var _isCancelled: Bool = false

	internal override var isCancelled: Bool {
		return _isCancelled
	}

	private var _isExecuting: Bool = false

	internal override var isExecuting: Bool {
		return _isExecuting
	}

	private var _isFinished: Bool = false

	internal var isComplete: Bool {
		return _isFinished
	}

	internal override var isFinished: Bool {
		return _isFinished
	}

	internal override var isAsynchronous: Bool {
		return true // URLRequestTask instances always run asynchronously
	}

	internal override var isReady: Bool {
		return task != nil
	}

}
