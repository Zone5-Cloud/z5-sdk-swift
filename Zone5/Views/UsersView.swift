import Foundation

public class UsersView: APIView {

	internal enum Endpoints: String, RequestEndpoint {
		case me = "/rest/users/me"
		case deleteUser = "/rest/users/delete/{userID}"
		case setUser = "/rest/users/set/User"
		case registerUser = "/rest/auth/register"
		case preRegisterUser = "/rest/auth/preregister"
		case login = "/rest/auth/login"
		case logout = "/rest/auth/logout"
		case exists = "/rest/auth/exists"
		case passwordReset = "/rest/auth/reset"
		case changePasswordSpecialized = "/rest/auth/set/password"
		case refreshToken = "/rest/auth/refresh"
		case setPreferences = "/rest/users/set/UserPreferences"
		case getPreferences = "/rest/users/prefs/{userID}"
		case getEmailStatus = "/rest/auth/status"

		var requiresAccessToken: Bool {
			switch self {
			case .login: return false
			case .exists: return false
			case .registerUser: return false
			case .passwordReset: return false
			case .getEmailStatus: return false
			default: return true
			}
		}
	}

	/// Return User information about the logged in user
	public func me(completion: @escaping (_ result: Result<User, Zone5.Error>) -> Void) {
		get(Endpoints.me, with: completion)
	}
	
	/// Register a new user account
	public func register(user: RegisterUser, completion: @escaping Zone5.ResultHandler<User>) {
		post(Endpoints.registerUser, body: user, with: completion)
	}
	
	/// Delete a user account
	public func deleteAccount(userID: Int, completion: @escaping Zone5.ResultHandler<VoidReply>) {
		let endpoint = Endpoints.deleteUser.replacingTokens(["userID": userID])
		get(endpoint, with: completion)
	}
	
	/// Login as a user and obtain a bearer token - clientId and clientSecret are not required in Specialized featureset
	public func login(email: String, password: String, clientID: String? = nil, clientSecret: String? = nil, completion: @escaping Zone5.ResultHandler<LoginResponse>) {
		guard let zone5 = zone5 else {
			completion(.failure(.invalidConfiguration))
			return
		}
		
		// Some hosts require clientID and clientSecret. Others do not.
		let body: JSONEncodedBody
		if !zone5.requiresClientSecret {
			body = LoginRequest(email: email, password: password)
		} else if let clientID = clientID, let clientSecret = clientSecret {
			body = LoginRequest(email: email, password: password, clientID: clientID, clientSecret: clientSecret)
		} else {
			// requires clientID and secretID but it has not been provided. FAIL.
			completion(.failure(.invalidConfiguration))
			return
		}
		
		post(Endpoints.login, body: body, expectedType: LoginResponse.self) { [weak self] result in
		defer { completion(result) }

			if let zone5 = self?.zone5, case .success(let loginResponse) = result, let token = loginResponse.token {
				zone5.accessToken = OAuthToken(rawValue: token)
			}
		}
	}
	
	/// Logout - this will invalidate any active JSESSION and will also invalidate your bearer token
	public func logout(completion: @escaping Zone5.ResultHandler<Bool>) {
		get(Endpoints.logout, parameters: nil, expectedType: Bool.self)  { [weak self] result in
			defer { completion(result) }
			
			if let zone5 = self?.zone5, case .success(let loggedOut) = result, loggedOut {
				// if we successfully logged out, invalidate the token
				zone5.accessToken = nil
			}
		}
	}
	
	/// Test if an email address is already registered in the system - true if the email already exists in the system
	public func isEmailRegistered(email: String, completion: @escaping Zone5.ResultHandler<Bool>) {
		let body = StringEncodedBody(email)
		post(Endpoints.exists, body: body, with: completion)
	}
	
	/// Request a password reset email - ie get a magic link to reset a user's password
	public func resetPassword(email: String, completion: @escaping Zone5.ResultHandler<Bool>) {
		let body = StringEncodedBody(email)
		post(Endpoints.passwordReset, body: body, with: completion)
	}
	
	/// Change a user's password - oldPassword is only required in Specialized environment
	public func changePassword(oldPassword: String?, newPassword: String, completion: @escaping Zone5.ResultHandler<VoidReply>) {
		guard let zone5 = zone5 else {
			completion(.failure(.invalidConfiguration))
			return
		}
		
		if zone5.requiresClientSecret {
			// we are in an authenticated session with client and secret, so we don't need old password. Just change new password.
			var user = User()
			user.password = newPassword
			post(Endpoints.setUser, body: user, expectedType: Bool.self) { result in
				// convert reply into a void so that changePasswordSpecialized and setUser are coerced to look the same
				switch result {
				case .failure(let error):
					completion(.failure(error))
				case .success(let result):
					if result {
						completion(.success(VoidReply()))
					} else {
						completion(.failure(Zone5.Error.unknown))
					}
				}
			}
		} else if let oldPassword = oldPassword {
			// Specialized usage with GIGYA token. We need old password and new password
			let body = NewPassword(old: oldPassword, new: newPassword)
			post(Endpoints.changePasswordSpecialized, body: body, with: completion)
		}
	}
	
	/// Refresh a bearer token - get a new token if the current one is nearing expiry
	public func refreshToken(completion: @escaping Zone5.ResultHandler<OAuthTokenAlt>) {
		get(Endpoints.refreshToken, parameters: nil, expectedType: OAuthTokenAlt.self)  { [weak self] result in
			defer { completion(result) }
			
			if let zone5 = self?.zone5, case .success(let token) = result {
				// if we successfully refreshed, update the token
				//zone5.accessToken = AccessToken(rawValue: token.token)
				zone5.accessToken = token
			}
		}
	}

	/// Set the given user's preferences, e.g. metric/imperial units
	public func getPreferences(userID: Int, completion: @escaping Zone5.ResultHandler<UsersPreferences>) {
		let endpoint = Endpoints.getPreferences.replacingTokens(["userID": userID])
		get(endpoint, with: completion)
	}
	
	/// Get the current user's preferences, e.g. metric/imperial units
	public func setPreferences(preferences: UsersPreferences, completion: @escaping Zone5.ResultHandler<Bool>) {
		post(Endpoints.setPreferences, body: preferences, with: completion)
	}
	
	public func getEmailValidationStatus(email: String, completion: @escaping Zone5.ResultHandler<[String:Bool]>) {
		let params: URLEncodedBody = [
			"email": email,
		]
		
		get(Endpoints.getEmailStatus, parameters: params, with: completion)
	}
}
