//
//  OAuthToken.swift
//  Zone5
//
//  Created by Jean Hall on 27/2/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

/// OAuth token model returned by the server for accessToken requests and refreshAccessToken requests
/// They are also constructed from LoginResponse
/// These may be legacy TP OAuth tokens (which will not have a refreshToken) or a Cognito token.
/// Cognito tokens will have refreshToken and expiresIn set
public struct OAuthToken: Codable, Equatable, AccessToken {
	
	/// String value of the OAuth token
	public let accessToken: String
	public var refreshToken: String?
	public var tokenType: String?
	public var scope: String?
	
	public var username: String? // attached locally from login response, not part of http oauth serialisation
	public var tokenExp: Milliseconds? // timestamp of expiry, ms since epoch, from login response or derived from expiresIn, not part of http oauth serialisation
	
	/// initializer called from login response
	public init(loginResponse: LoginResponse) {
		self.accessToken = loginResponse.token ?? ""
		self.refreshToken = loginResponse.refresh
		self.username = loginResponse.user?.email
		if let expiresIn = loginResponse.expiresIn {
			self.tokenExp = Date().addingTimeInterval(expiresIn).milliseconds
		} else {
			// only use tokenExp if expiresIn was not given.
			// calculating tokenExp from system time + expiresIn is more reliable as
			// it is not affacted by clock differences between Server and Client
			self.tokenExp = loginResponse.tokenExp
		}
	}
	
	public init(token: String, refresh: String? = nil, expiresAt: Date, username: String) {
		self.init(token: token, refresh: refresh, tokenExp: expiresAt.milliseconds, username: username)
	}
	
	@available(*, deprecated, message: "tokenExp is now defined as Milliseconds, pass as Milliseconds`")
	public init(token: String, refresh: String? = nil, tokenExp: Int, username: String) {
		self.init(token: token, refresh: refresh, tokenExp: Milliseconds(rawValue: tokenExp), username: username)
	}
	
	public init(token: String, refresh: String? = nil, tokenExp: Milliseconds, username: String) {
		self.accessToken = token
		self.refreshToken = refresh
		self.tokenExp = tokenExp
		self.username = username
	}
	
	/// internal, only used in unit tests to simulate expected decoded tokens
	internal init(token: String, refresh: String? = nil, expiresIn: TimeInterval? = nil) {
		self.accessToken = token
		self.refreshToken = refresh
		self.tokenExp = expiresIn != nil ? Date().addingTimeInterval(expiresIn!).milliseconds : nil
	}
	
	public var rawValue: String {
		return accessToken
	}
	
	public func equals(_ other: AccessToken?) -> Bool {
		if let other = other as? OAuthToken, other.accessToken == self.accessToken, other.refreshToken == self.refreshToken, other.tokenExp == self.tokenExp, other.username == self.username, other.scope == self.scope, other.tokenType == self.tokenType {
			return true
		}
		
		return false
	}
	
	// MARK: Codable

	private enum CodingKeys: String, CodingKey {
		// Standard OAuth token returned from server
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
		case tokenType = "token_type"
		case scope = "scope"
		
		// file serialisation for saving
		case username = "username"
		case tokenExp = "token_exp"
	}
	
	// only used in decode
	private enum AdditionalCodingKeys: String, CodingKey {
		case expiresIn = "expires_in"
}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let container2 = try decoder.container(keyedBy: AdditionalCodingKeys.self)
		self.username = try container.decodeIfPresent(String.self, forKey: .username)
		self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
		self.accessToken = try container.decode(String.self, forKey: .accessToken)
		self.scope = try container.decodeIfPresent(String.self, forKey: .scope)
		self.tokenType = try container.decodeIfPresent(String.self, forKey: .tokenType)

		if let expiresIn = try container2.decodeIfPresent(TimeInterval.self, forKey: .expiresIn) {
			self.tokenExp = Date().addingTimeInterval(expiresIn).milliseconds
		} else {
			self.tokenExp = try container.decodeIfPresent(Milliseconds.self, forKey: .tokenExp)
		}
	}
}
