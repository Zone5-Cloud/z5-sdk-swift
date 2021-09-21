//
//  LoginRequest.swift
//  Zone5
//
//  Created by Jean Hall on 2/3/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

/// body used in login and refresh endpoints
internal struct LoginRequest: JSONEncodedBody {
	var email: String
	var password: String?
	var refreshToken: String?
	let token: String = "true"
	var clientID: String?
	var clientSecret: String?
	var accept: [String]?
	var billingCountry: String?
	
	private enum CodingKeys: String, CodingKey {
		case email = "username"
		case password
		case refreshToken = "refresh"
		case token
		case clientID = "clientId"
		case clientSecret
		case accept
		case billingCountry
	}
	
	/// used  in login using a username and password
	public init(email: String, password: String, clientID: String? = nil, clientSecret: String? = nil, accept: [String]? = nil, billingCountry: String? = nil) {
		self.email = email
		self.password = password
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.accept = accept
		self.billingCountry = billingCountry
	}
	
	/// used in refresh using username and refresh token
	public init(email: String, refreshToken: String, clientID: String? = nil, clientSecret: String? = nil, accept: [String]? = nil, billingCountry: String? = nil) {
		self.email = email
		self.refreshToken = refreshToken
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.accept = accept
		self.billingCountry = billingCountry
	}
}
