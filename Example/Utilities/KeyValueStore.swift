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
	
	var oauthToken: OAuthToken? {
		get {
			if let data = userDefaults.data(forKey: "Zone5_oauth_token"), let token = try? JSONDecoder().decode(OAuthToken.self, from: data) {
				return token
			} else {
				return nil
			}
		}
		set {
			if let newValue = newValue, !newValue.accessToken.isEmpty, let data = try? JSONEncoder().encode(newValue) {
				userDefaults.set(data, forKey: "Zone5_oauth_token")
			} else {
				userDefaults.removeObject(forKey: "Zone5_oauth_token")
			}
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
