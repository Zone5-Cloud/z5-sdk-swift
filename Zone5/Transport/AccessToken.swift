import Foundation

/// Token that can be used to sign relevant requests as the user it represents.
public protocol AccessToken: Codable, CustomStringConvertible, CustomDebugStringConvertible {

	/// The string value of the token.
	var rawValue: String { get }
	var tokenExp: Int? { get set }
	var username: String? { get set }
	var refreshToken: String? { get }
	var accessToken: String { get }
	
	func equals(_ other: AccessToken?) -> Bool
}

extension AccessToken  {

	public var description: String {
		return rawValue
	}

}

extension AccessToken {

	public var debugDescription: String {
		return "\(type(of: self))(\(rawValue))"
	}

}
