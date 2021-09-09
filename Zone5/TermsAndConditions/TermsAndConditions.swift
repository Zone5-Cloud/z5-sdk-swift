//
//  Terms.swift
//  Zone5
//
//  Created by Jean Hall on 28/4/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import Foundation

public struct TermsAction: Codable, JSONEncodedBody {
	public var firstName: String?
	public var lastName: String?
	public var email: String
	public var uid: String
	public var ts: Int?
}

/// Returned by /rest/auth/terms/required
public struct TermsAndConditions: Codable, JSONEncodedBody {
	// matches the server side TermsAndConditionsVersionView
	public var companyId: String
	public var termsId: String
	public var alias: String?
	public var displayName: String
	public var filename: String?
	public var url: URL?
	public var version: Int
	public var displayVersion: String?
	public var entityType: String
	public var active: Bool?
	public var status: String?
	public var createdBy: TermsAction?
	public var publishedBy: TermsAction?
}
