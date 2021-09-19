//
//  KeyValueStore.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 8/11/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import Foundation
import Zone5

class KeyValueStore {

	static var shared = KeyValueStore()

	let userDefaults: UserDefaults

	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults
	}

	// MARK: Values

	private let defaultURL = URL(string: "https://example.com")!

	var baseURLString: String {
		get { return userDefaults.string(forKey: "Zone5_baseURL") ?? defaultURL.absoluteString }
		set { userDefaults.set(newValue, forKey: "Zone5_baseURL") }
	}

	var baseURL: URL {
		get { return URL(string: baseURLString) ?? defaultURL }
		set { baseURLString = newValue.absoluteString }
	}
	
	var userEmail: String {
		get { return userDefaults.string(forKey: "Zone5_userEmail") ?? "" }
		set {
			if !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_userEmail")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_userEmail")
			}
		}
	}
	
	private var token: String? {
		get { return userDefaults.string(forKey: "Zone5_token") }
		set {
			if let newValue = newValue, !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_token")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_token")
			}
		}
	}
	
	private var refresh: String? {
		get { return userDefaults.string(forKey: "Zone5_token_refresh") }
		set {
			if let newValue = newValue, !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_token_refresh")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_token_refresh")
			}
		}
	}
	
	private var tokenExp: Int? {
		get { return userDefaults.integer(forKey: "Zone5_token_expiry") }
		set {
			if let newValue = newValue, newValue > 0 {
				userDefaults.set(newValue, forKey: "Zone5_token_expiry")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_token_expiry")
			}
		}
	}
	
	var oauthToken: OAuthToken? {
		get {
			if let token = token, let tokenExp = tokenExp {
				return OAuthToken(token: token, refresh: refresh, expiresIn: tokenExp, username: userEmail)
			}
			
			return nil
		}
		set {
			token = newValue?.accessToken
			refresh = newValue?.refreshToken
			tokenExp = newValue?.tokenExp
		}
	}
	
	var clientID: String? {
		get { return userDefaults.string(forKey: "Zone5_clientID") }
		set {
			if let newValue = newValue, !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_clientID")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_clientID")
			}
		}
	}

	var clientSecret: String? {
		get { return userDefaults.string(forKey: "Zone5_clientSecret") }
		set {
			if let newValue = newValue, !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_clientSecret")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_clientSecret")
			}
		}
	}
	
	var userAgent: String? {
		get { return userDefaults.string(forKey: "Zone5_userAgent") }
		set {
			if let newValue = newValue, !newValue.isEmpty {
				userDefaults.set(newValue, forKey: "Zone5_userAgent")
			}
			else {
				userDefaults.removeObject(forKey: "Zone5_userAgent")
			}
		}
	}

}
