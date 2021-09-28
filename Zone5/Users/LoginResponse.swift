//
//  LoginResponse.swift
//  Zone5
//
//  Created by Jean Hall on 26/2/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

public struct LoginResponse: Codable {
	/// Collection of companies which this user belongs / has a relationship with
	public var companies: [Int]?
	
	/// List of roles which this user has
	public var roles: [Roles]?
	
	/// Primary branding company (if any)
	public var branding: Company?
	
	/// The actual user
	public var user: User?
	
	/// Bearer token
	public var token: String?
	
	/// Bearer token expiry (ms since Epoch)
	public var tokenExp: Milliseconds?
	
	/// seconds until expiry. This allows for differences in Server clock vs Client clock as the Client can calculate as Date() + Double(expiresIn)
	public var expiresIn: TimeInterval?
	
	public var refresh: String?
	
	public var updatedTerms: [UpdatedTerms]? // List of terms (previously accepted) that have been updated and need re-acceptance
	
	public var needChangePassword: Bool? // flag to indicate that the user needs to change their password
	
	public init() { }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.token = try container.decodeIfPresent(String.self, forKey: .token)
		
		// This is an intentional swallowing of errors. If a login received a 200 and a useable token (above) then
		// we should not impede the success of the login and the saving of the above token. Otherwise we risk
		// making the entire SDK unusable as a json structure inconsistency could stop a user from logging in and
		// hence they will be unable to call any authenticated endpoints
		self.companies = try? container.decodeIfPresent([Int].self, forKey: .companies)
		self.roles = try? container.decodeIfPresent([Roles].self, forKey: .roles)
		self.branding = try? container.decode(Company.self, forKey: .branding)
		self.user = try? container.decodeIfPresent(User.self, forKey: .user)
		self.tokenExp = try? container.decodeIfPresent(Milliseconds.self, forKey: .tokenExp)
		self.expiresIn = try? container.decodeIfPresent(TimeInterval.self, forKey: .expiresIn)
		self.refresh = try? container.decodeIfPresent(String.self, forKey: .refresh)
		self.updatedTerms = try? container.decodeIfPresent([UpdatedTerms].self, forKey: .updatedTerms)
		self.needChangePassword = try? container.decodeIfPresent(Bool.self, forKey: .needChangePassword)
	}
}
