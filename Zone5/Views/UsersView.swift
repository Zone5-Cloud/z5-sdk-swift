import Foundation

public class UsersView: APIView {

	internal enum Endpoints: String, InternalRequestEndpoint {
		case me = "/rest/users/me"
		case deleteUser = "/rest/users/delete/{userID}"
		case setUser = "/rest/users/set/User"
		case registerUser = "/rest/auth/register"
		case preRegisterUser = "/rest/auth/preregister"
		case login = "/rest/auth/login"
		case logout = "/rest/auth/logout"
		case requiredTerms = "/rest/auth/terms/required"
		case exists = "/rest/auth/exists"
		case passwordReset = "/rest/auth/reset"
		case changePassword = "/rest/auth/set/password"
		case refreshToken = "/rest/auth/refresh"
		case setPreferences = "/rest/users/set/UserPreferences"
		case getPreferences = "/rest/users/prefs/{userID}"
		case getEmailStatus = "/rest/auth/status"
		case passwordComplexity = "/rest/auth/password-complexity"
		case reconfirmEmail = "/rest/auth/reconfirm"

		var requiresAccessToken: Bool {
			switch self {
			case .login: return false
			case .exists: return false
			case .registerUser: return true // register can optionally accept bearer token
			case .passwordReset: return false
			case .getEmailStatus: return false
			case .reconfirmEmail: return false
			default: return true
			}
		}
	}

	/// Return User information about the logged in user
	@discardableResult
	public func me(completion: @escaping (_ result: Result<User, Zone5.Error>) -> Void) -> PendingRequest? {
		return get(Endpoints.me, with: completion)
	}
	
	/// Register a new user account
	@discardableResult
	public func register(user: RegisterUser, completion: @escaping Zone5.ResultHandler<User>) -> PendingRequest? {
		return post(Endpoints.registerUser, body: user, with: completion)
	}
	
	/// Delete a user account
	@discardableResult
	public func deleteAccount(userID: Int, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		let endpoint = Endpoints.deleteUser.replacingTokens(["userID": userID])
		return get(endpoint, with: completion)
	}
	
	/// Login as a user and obtain a bearer token - clientId and clientSecret are not required in Specialized featureset
	/// Don't pass back a PendingRequest as this is not something that we can cancel mid-request
	public func login(email: String, password: String, clientID: String? = nil, clientSecret: String? = nil, accept: [String]? = nil, completion: @escaping Zone5.ResultHandler<LoginResponse>) {
		guard let zone5 = zone5 else {
			completion(.failure(.invalidConfiguration))
			return
		}
		
		// Some hosts require clientID and clientSecret. Others do not.
		let body: JSONEncodedBody
		if let clientID = clientID {
			body = LoginRequest(email: email, password: password, clientID: clientID, clientSecret: clientSecret, accept: accept)
		} else {
			// requires clientID but it has not been provided. FAIL.
			completion(.failure(.invalidConfiguration))
			return
		}
        
		_ = post(Endpoints.login, body: body, expectedType: LoginResponse.self) { result in
		defer { completion(result) }
			if case .success(let loginResponse) = result {
				zone5.accessToken = OAuthToken(loginResponse: loginResponse)
			}
		}
	}
	
	/// Logout - this will invalidate any active JSESSION and will also invalidate your bearer token
	/// Don't pass back a PendingRequest as this is not something that we can cancel mid-request
	public func logout(completion: @escaping Zone5.ResultHandler<Bool>) {
		_ = get(Endpoints.logout, parameters: nil, expectedType: Bool.self)  { [weak self] result in
			defer { completion(result) }
			
			if let zone5 = self?.zone5 {
				// invalidate the token and clear cookies
				zone5.accessToken = nil
				if let url = zone5.baseURL {
					let cookieStore = HTTPCookieStorage.shared
					for cookie in cookieStore.cookies(for: url) ?? [] {
						z5DebugLog("logout: Deleting cookie \(cookie.name)", level: .debug)
						cookieStore.deleteCookie(cookie)
					}
				}
			}
		}
	}
	
	/// Test if an email address is already registered in the system - true if the email already exists in the system
	@discardableResult
	public func isEmailRegistered(email: String, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		let body = StringEncodedBody(email)
		return post(Endpoints.exists, body: body, with: completion)
	}
	
	/// Request a password reset email - ie get a magic link to reset a user's password
	@discardableResult
	public func resetPassword(email: String, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		let body = StringEncodedBody(email)
		return post(Endpoints.passwordReset, body: body, with: completion)
	}
	
	/// Update properties on the User
	@discardableResult
	public func updateUser(user: User, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		post(Endpoints.setUser, body: user, with: completion)
	}
	
	/// Change a user's password - oldPassword is only required in Specialized environment so is optional
	public func changePassword(oldPassword: String?, newPassword: String, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) {
		let body = NewPassword(old: oldPassword, new: newPassword)
		_ = post(Endpoints.changePassword, body: body, with: completion)
	}
	
	/// Refresh a bearer token - get a new token if the current one is nearing expiry
	public func refreshToken(completion: @escaping Zone5.ResultHandler<OAuthTokenAlt>) {
		_ = get(Endpoints.refreshToken, parameters: nil, expectedType: OAuthTokenAlt.self) { [weak self] result in
			defer { completion(result) }
			
			if let zone5 = self?.zone5, case .success(let token) = result {
				// if we successfully refreshed, update the token
				zone5.accessToken = token
			}
		}
	}
	
	/// Get the list of required terms for the currently configured clientID. This is an unauthenticated endpoint and can be called before logging in.
	public func getRequiredTerms(completion: @escaping Zone5.ResultHandler<[TermsAndConditions]>) -> PendingRequest? {
		return get(Endpoints.requiredTerms, with: completion)
	}

	/// Set the given user's preferences, e.g. metric/imperial units
	@discardableResult
	public func getPreferences(userID: Int, completion: @escaping Zone5.ResultHandler<UsersPreferences>) -> PendingRequest? {
		let endpoint = Endpoints.getPreferences.replacingTokens(["userID": userID])
		return get(endpoint, with: completion)
	}
	
	/// Get the current user's preferences, e.g. metric/imperial units
	@discardableResult
	public func setPreferences(preferences: UsersPreferences, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		return post(Endpoints.setPreferences, body: preferences, with: completion)
	}
	
	/// Get the Email validation for the given email
	@discardableResult
	public func getEmailValidationStatus(email: String, completion: @escaping Zone5.ResultHandler<[String:Bool]>) -> PendingRequest? {
		let params: URLEncodedBody = [
			"email": email,
		]
		
		return get(Endpoints.getEmailStatus, parameters: params, with: completion)
	}
	
	@discardableResult
	public func passwordComplexity(completion: @escaping (_ result: Result<String, Zone5.Error>) -> Void) -> PendingRequest? {
		return get(Endpoints.passwordComplexity, with: completion)
	}
	
	@discardableResult
	public func reconfirmEmail(email: String, completion: @escaping (_ result: Result<Zone5.VoidReply, Zone5.Error>) -> Void) -> PendingRequest? {
		let params: URLEncodedBody = [
			"email": email,
		]
		
		return get(Endpoints.reconfirmEmail, parameters: params, with: completion)
	}
}
