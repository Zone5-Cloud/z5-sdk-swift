//
//  Result.swift
//  Zone5Tests
//
//  Created by Daniel Farrelly on 7/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import Foundation
import Zone5
import XCTest

extension Result {

    typealias Expectation = ResultExpectation<Success, Failure>

	static func success(_ closure: () -> Success) -> Self {
		return .success(closure())
	}

	static func failure(_ closure: () -> Failure) -> Self {
		return .failure(closure())
	}

}

final class ResultExpectation<Success, Failure>: XCTestExpectation where Failure: Error {

    typealias SuccessAssertionsHandler = (_ lhs: Success, _ rhs: Success) -> Void

    let expectedResult: Result<Success, Failure>

    let assertionsOnSuccess: SuccessAssertionsHandler

    init(for expectedResult: Result<Success, Failure>, description expectationDescription: String = "", assertionsOnSuccess: @escaping SuccessAssertionsHandler) {
        self.expectedResult = expectedResult
        self.assertionsOnSuccess = assertionsOnSuccess
        super.init(description: expectationDescription)
    }

    convenience init(for expectedResult: Result<Success, Failure>, description expectationDescription: String = "") where Success == Zone5.VoidReply {
        self.init(for: expectedResult, description: expectationDescription) { _, _ in
            // VoidReply response needs no further validation
        }
    }

    convenience init(for expectedResult: Result<Success, Failure>, description expectationDescription: String = "") where Success: Equatable {
        self.init(for: expectedResult, description: expectationDescription) { lhs, rhs in
            XCTAssertEqual(lhs, rhs, "Result returned by test should match expected result.")
        }
    }

    @available(*, deprecated, message: "Use `fulfill(with:)` instead.")
    override func fulfill() {
        fatalError("ResultExpectation should be fulfilled using the method that allows a test result to be provided.")
    }

    func fulfill(with testResult: Result<Success, Failure>) {
        switch (testResult, expectedResult) {
        case (.failure(let lhs), .failure(let rhs)):
            validateErrors(lhs, rhs)

        case (.success(let lhs), .success(let rhs)):
            assertionsOnSuccess(lhs, rhs)

        default:
            XCTFail("Test result does not match expected result: \(String(describing: testResult)) != \(expectedResult).")
        }

        super.fulfill()
    }

    private func validateErrors(_ lhs: Swift.Error, _ rhs: Swift.Error) {
        switch (lhs, rhs) {
        case (_, Zone5.Error.unknown):
            return // For testing purposes, unknown is used as a catch-all

        case (nil, nil),
            (Zone5.Error.invalidParameters, Zone5.Error.invalidParameters),
            (Zone5.Error.invalidConfiguration, Zone5.Error.invalidConfiguration),
            (Zone5.Error.unexpectedRequestBody, Zone5.Error.unexpectedRequestBody),
            (Zone5.Error.missingRequestBody, Zone5.Error.missingRequestBody),
            (Zone5.Error.failedEncodingRequestBody, Zone5.Error.failedEncodingRequestBody):
            return

        case (Zone5.Error.serverError(let message1), Zone5.Error.serverError(let message2)):
            XCTAssertEqual(message1.statusCode, message2.statusCode)

        case (Zone5.Error.failedDecodingResponse(let error1), Zone5.Error.failedDecodingResponse(let error2)):
            validateErrors(error1, error2)

        case (Zone5.Error.transportFailure(let error1), Zone5.Error.transportFailure(let error2)):
            validateErrors(error1, error2)

        default:
            XCTAssertEqual((lhs as NSError).domain, (rhs as NSError).domain, "Error returned by test should match expected domain.")
            XCTAssertEqual((lhs as NSError).code, (rhs as NSError).code, "Error returned by test should match expected error code.")
        }
    }

}

