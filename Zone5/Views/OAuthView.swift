import Foundation

public class OAuthView: APIView {

	private enum Endpoints: String, InternalRequestEndpoint {
		case accessToken = "/rest/oauth/access_token"
		case adhocAccessToken = "/rest/oauth/newtoken/{clientID}"
		case refreshToken = "/rest/auth/refresh"
		
		var requiresAccessToken: Bool {
			switch self {
			case .accessToken: return false
			case .refreshToken: return false
			case .adhocAccessToken: return true
			}
		}
	}

	/// Perform user authentication with the given `username` and `password`.
	///
	/// This method requires that the SDK has been configured with a valid `clientID` and `clientSecret`, using
	/// `Zone5.configure(baseURL:clientID:clientSecret)`. If this has not been done, the method will call the completion
	/// with `Zone5.Error.invalidConfiguration`.
	///
	/// - Parameters:
	///   - username: The user's username.
	///   - password: The user's password.
	///   - completion: Handler called the authentication completes. If successful, the result will contain an access
	///   	token that can be used to authenticate the user in future sessions, and otherwise will contain a
	///   	`Zone5.Error` value which represents the problem that occurred.
	///
	///	On success the returned access token is automatically saved and will be the access token used from here on.
	///
	/// Does not pass back a PendingRequest as this is not something that we want to cancel mid-request
	public func accessToken(username: String, password: String, completion: @escaping (_ result: Result<OAuthToken, Zone5.Error>) -> Void) {
		guard let zone5 = zone5, zone5.isConfigured else {
			completion(.failure(.invalidConfiguration))

			return
		}

		let body: URLEncodedBody = [
			"username": username,
			"password": password,
			"client_id": zone5.clientID,
			"client_secret": zone5.clientSecret,
			"grant_type": "password",
			"redirect_uri": zone5.redirectURI,
		]

		_ = post(Endpoints.accessToken, body: body, expectedType: OAuthToken.self) { result in
			if case .success(var token) = result {
				if let expiresIn = token.expiresIn {
					token.tokenExp = Date().addingTimeInterval(Double(expiresIn)).milliseconds.rawValue
				}
				
				token = zone5.setToken(to: token)
				completion(Zone5.Result.success(token))
			} else {
				completion(result)
			}
		}
	}
	
	/// Refresh the existing bearer token
	///
	/// This method requires that the SDK has been configured with a valid `clientID` and optionally `clientSecret`, using
	/// `Zone5.configure(baseURL:clientID:clientSecret)`.
	/// It also needs to be configured with a valid OAuthToken.
	/// If these conditions are not met, the method will call the completion with `Zone5.Error.invalidConfiguration`.
	///
	/// - Parameters:
	/// 	- username: The user's username. If not passed, the configured username is used.
	/// 	- completion: Handler called the authentication completes. If successful, the result will contain an access
	/// 	- accept: optional list of terms to accept
	/// 	- billingCountry: optional country that terms were accepted in
	///   	token that can be used to authenticate the user in future sessions, and otherwise will contain a
	///   	`Zone5.Error` value which represents the problem that occurred.
	///
	///	On success the returned access token is automatically saved and will be the access token used from here on.
	///
	/// Does not pass back a PendingRequest as this is not something that we want to cancel mid-request
	///
	/// If you are using the sdk for all comms then explicit use of this method is unnessessary as it is done implicitely whenever your token nears expiry
	public func refreshAccessToken(username: String? = nil, refreshToken: String? = nil, accept: [String]? = nil, billingCountry: String? = nil, completion: @escaping (_ result: Result<OAuthToken, Zone5.Error>) -> Void) {
		guard let zone5 = zone5, let username = username ?? zone5.accessToken?.username, let refreshToken = refreshToken ?? zone5.accessToken?.refreshToken else {
			completion(.failure(.invalidConfiguration))
			return
		}
		
		_ = post(Endpoints.refreshToken, body: LoginRequest(email: username, refreshToken: refreshToken, accept: accept, billingCountry: billingCountry), expectedType: LoginResponse.self) { result in
			if case .success(let loginResponse) = result {
				let token = zone5.setToken(to: OAuthToken(loginResponse: loginResponse))
				
				if let updatedTerms = loginResponse.updatedTerms {
					zone5.notificationCenter.post(name: Zone5.updatedTermsNotification, object: zone5, userInfo: [
						"updatedTerms": updatedTerms
					])
				}
				
				completion(.success(token))
			} else if case .failure(let error) = result {
				completion(.failure(error))
			} else {
				completion(.failure(.unknown))
			}
		}
	}
	
	/// Fetch an adhoc access token on behalf of another app (different clientID) that can be used to authenticate with the zone5 server.
	/// This is an authenticated endpoint so requires there to be a valid configured access token.
	/// - Parameters:
	/// 	- clientID: The clientID to request an adhoc token for.
	/// - returns: a PendingRequest that can be canceled.
	@discardableResult
	public func adhocAccessToken(for clientID: String, completion: @escaping (_ result: Result<OAuthToken, Zone5.Error>) -> Void) -> PendingRequest? {
		let endpoint = Endpoints.adhocAccessToken.replacingTokens(["clientID": clientID])
		return get(endpoint, with: completion)
	}
}
