import Foundation

/// Token that can be used to sign relevant requests as the user it represents.
public protocol AccessToken: Codable, CustomStringConvertible, CustomDebugStringConvertible {

	var tokenExp: Milliseconds? { get set }
	var username: String? { get set }
	var refreshToken: String? { get }
	var accessToken: String { get }
	
	func equals(_ other: AccessToken?) -> Bool
}

extension AccessToken  {
	
	/// The string value of the token.
	public var rawValue: String {
		return accessToken
	}

	public var description: String {
		return rawValue
	}
	
}

extension AccessToken {

	public var debugDescription: String {
		return "\(type(of: self))(\(rawValue))"
	}

}

extension AccessToken {
	
	public var expiresAt: Date? {
		get {
			guard let tokenExp = tokenExp else {
				return nil
			}
			
			return Date(tokenExp)
		}
		
		set {
			tokenExp = newValue?.milliseconds
		}
	}
	
	public var expiresIn: TimeInterval? {
		return expiresAt?.timeIntervalSinceNow
	}
	
	internal var requiresRefresh: Bool {
		guard let refresh = refreshToken, !refresh.isEmpty else {
			// we can only refresh ourself if we have a refresh token
			return false
		}
		
		// missing, nearing or past expiry
		return expiresIn ?? 0 <= Zone5.refreshExpiresInThreshold
	}
}

extension Zone5 {
	static fileprivate let refreshExpiresInThreshold: TimeInterval = 30.0
}
