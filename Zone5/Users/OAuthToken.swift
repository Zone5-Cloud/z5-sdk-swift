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
	public var expiresIn: Int? // seconds til expiry
	public var scope: String?
	
	public var username: String? // attached locally from login response, not part of http oauth serialisation
	public var tokenExp: Int? // timestamp of expiry, ms since epoch, from login response or derived from expiresIn, not part of http oauth serialisation
	
	public init(rawValue: String) {
		accessToken = rawValue
	}
	
	/// initializer called from login response
	public init(loginResponse: LoginResponse) {
		self.accessToken = loginResponse.token ?? ""
		self.refreshToken = loginResponse.refresh
		self.username = loginResponse.user?.email
		self.expiresIn = loginResponse.expiresIn
		if expiresIn == nil {
			// only use tokenExp if expiresIn was not given.
			// calculating tokenExp from system time + expiresIn is more reliable as
			// it is not affacted by clock differences between Server and Client
			self.tokenExp = loginResponse.tokenExp
		}
		calculateExpiry()
	}
	
	public init(token: String, refresh: String? = nil, tokenExp: Int? = nil, username: String? = nil) {
		self.accessToken = token
		self.refreshToken = refresh
		self.tokenExp = tokenExp
		self.username = username
		calculateExpiry()
	}
	
	public init(token: String, refresh: String? = nil, expiresIn: Int, username: String? = nil) {
		self.accessToken = token
		self.refreshToken = refresh
		self.expiresIn = expiresIn
		self.username = username
		calculateExpiry()
	}
	
	public var rawValue: String {
		return accessToken
	}
	
	public func equals(_ other: AccessToken?) -> Bool {
		if let other = other as? OAuthToken, other.accessToken == self.accessToken, other.refreshToken == self.refreshToken, other.tokenExp == self.tokenExp {
			return true
		}
		
		return false
	}
	
	private mutating func calculateExpiry() {
		if expiresIn == nil, let exp = tokenExp {
			self.expiresIn = Int((Double(exp) / 1000.0) - Date().timeIntervalSince1970)
		} else if tokenExp == nil, let expiresIn = expiresIn {
			self.tokenExp = (Date() + Double(expiresIn)).milliseconds.rawValue
		}
	}
	
	// MARK: Codable

	private enum CodingKeys: String, CodingKey {
		// Standard OAuth token returned from server
		case accessToken = "access_token"
		case refreshToken = "refresh_token"
		case tokenType = "token_type"
		case expiresIn = "expires_in"
		case scope = "scope"
		
		// to file serialisation for saving
		case username = "username"
		case tokenExp = "token_exp"
	}
}
