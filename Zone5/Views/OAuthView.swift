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
	/// `Zone5.configure(baseURL:clientID:clientSecret)`.
	///
	/// If `clientID` and `clientSecret` requirements are not satisfied, the server will respond with an appropriate 401 response.
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
	public func accessToken(username: String, password: String, redirectURI: String = "https://localhost", completion: @escaping (_ result: Result<OAuthToken, Zone5.Error>) -> Void) {
		guard let zone5 = zone5 else {
			completion(.failure(.invalidConfiguration))
			return
		}

		let body: URLEncodedBody = [
			"username": username,
			"password": password,
			"client_id": zone5.clientID,
			"client_secret": zone5.clientSecret,
			"grant_type": "password",
			"redirect_uri": redirectURI,
		]

		_ = post(Endpoints.accessToken, body: body, expectedType: OAuthToken.self) { result in
			if case .success(var token) = result {
				// set the username to the passed in username that we authenticated with to get this token
				token.username = username
				// save token for future use (will trigger change notification)
				zone5.accessToken = token
				completion(Zone5.Result.success(token))
			} else {
				completion(result)
			}
		}
	}
	
	/// Refresh the existing bearer token
	///
	/// This method requires that the SDK has been configured with a valid `clientID` and optionally `clientSecret` depending on `clientID` settings,
	/// Configure these values using `Zone5.configure(baseURL:clientID:clientSecret)`.
	///
	/// It also needs to be configured with a valid refreshable OAuthToken.
	///
	/// If `clientID` and `clientSecret` requirements are not satisfied, the server will respond with an appropriate 401 response.
	///
	/// If there is no token to refresh the method will call the completion with `Zone5.Error.invalidConfiguration`.
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
			switch result {
				case .success(let loginResponse):
					var token = OAuthToken(loginResponse: loginResponse)
					// set the username on the token to the username we authenticated with
					token.username = username
					// save token for future use (will trigger change notification)
					zone5.accessToken = token
					
					// notify any change in terms
					if let updatedTerms = loginResponse.updatedTerms, !updatedTerms.isEmpty {
						zone5.notificationCenter.post(name: Zone5.updatedTermsNotification, object: zone5, userInfo: [
							"updatedTerms": updatedTerms
						])
					}
						completion(.success(token))
				case .failure(let error):
					completion(.failure(error))
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
