//
//  OAuthTokenAlt.swift
//  Zone5
//
//  Created by Jean Hall on 27/2/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

/// OAuth token model returned by the server for gigya refresh token requests
/// These OAuth tokens are Gigya tokens
@available(*, deprecated, message: "Gigya is no longer supported. Use OAuthToken")
public struct OAuthTokenAlt: Codable, AccessToken {

	/// The string value of the token.
	public var token: String
	
	/// timestamp of when this token expires, ms since epoch
	public var tokenExp: Milliseconds?
	
	public var username: String?
	
	public init(rawValue: String) {
		token = rawValue
	}
	
	public var rawValue: String {
		return token
	}
	
	public var accessToken: String {
		return token
	}
	
	public var refreshToken: String? {
		return nil
	}

	public func equals(_ other: AccessToken?) -> Bool {
		if let other = other as? OAuthTokenAlt, other.token == self.token, other.tokenExp == self.tokenExp {
			return true
		}
		
		return false
	}
}
