import Foundation

/// The entrance point to the rest of the API. This class encapsulates client configuration, and provides access to the
/// individual endpoints, grouped into views.
final public class Zone5 {

	/// Shared instance of the Zone5 SDK
	public static let shared = Zone5()

	/// A light wrapper of the URLSession API, which enables communication with the server endpoints.
	internal let httpClient: Zone5HTTPClient

	internal static let specializedServer: String = "api-sp.todaysplan.com.au"
	internal static let specializedStagingServer: String = "api-sp-staging.todaysplan.com.au"
	
	public static let authTokenChangedNotification = Notification.Name("authTokenChangedNotification")
	
	init(httpClient: Zone5HTTPClient = .init()) {
		self.httpClient = httpClient

		httpClient.zone5 = self
	}

	// MARK: Configuring the SDK

	/// The access token representing the currently authenticated user.
	///
	/// This property automatically captures the token returned by the server when using methods such as
	/// `OAuthView.accessToken(username:password:completion:)`, but can also be set using a token that was stored
	/// during a previous session.
	public internal(set) var accessToken: AccessToken? {
		didSet {
			if var token = accessToken, !token.equals(oldValue) {
				if token.username == nil {
					token.username = oldValue?.username
					accessToken = token
				}
				notificationCenter.post(name: Zone5.authTokenChangedNotification, object: self, userInfo: [
					"accessToken": token
				])
			} else if accessToken == nil && oldValue != nil {
				notificationCenter.post(name: Zone5.authTokenChangedNotification, object: self)
			}
		}
	}
    
    public var debugLogging: Bool = false

	/// The root URL for the server that we want to communicate with.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public internal(set) var baseURL: URL?

	/// The clientID, as provided by Zone5.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public internal(set) var clientID: String?

	/// The secret key, as provided by Zone5.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public internal(set) var clientSecret: String?
	
	/// The user agent to set in the User-Agent header
	public internal(set) var userAgent: String?

	public var redirectURI: String = "https://localhost"
	
	public var notificationCenter: NotificationCenter = .default

	/// Configures the SDK to use the application specified by the given `clientID` and `clientSecret`.
	/// - Parameters:
	///   - baseURL: The API url to use.
	///   - clientID: The clientID, as provided by Zone5.
	///   - clientSecret: The secret key, as provided by Zone5.
	///   - accessToken: An access token representing a user authenticated during a previous session. If `nil`, any
	///   		existing access token will be cleared.
	public func configure(for baseURL: URL, clientID: String? = nil, clientSecret: String? = nil, userAgent: String? = nil, accessToken: AccessToken?) {
		self.baseURL = baseURL
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.userAgent = userAgent
		self.accessToken = accessToken
	}

	/// Configures the SDK to use the application specified by the given `clientID` and `clientSecret`.
	/// - Parameters:
	///   - baseURL: The API url to use.
	///   - clientID: The clientID, as provided by Zone5.
	///   - clientSecret: The secret key, as provided by Zone5.
	public func configure(for baseURL: URL, clientID: String? = nil, clientSecret: String? = nil, userAgent: String? = nil) {
		self.baseURL = baseURL
		self.clientID = clientID
		self.clientSecret = clientSecret
		self.userAgent = userAgent
	}

	/// Configures the SDK on behalf of a user, represented by the given `accessToken`.
	///
	/// As this method does not include the `clientID` or `clientSecret`, configuring the SDK this way will not allow
	/// for user authentication, and is intended for instances where the `accessToken` is sourced externally, such as
	/// through single sign-on.
	/// - Parameters:
	///   - baseURL: The API url to use.
	///   - accessToken: An access token that represents your user and client.
	public func configure(for baseURL: URL, accessToken: AccessToken) {
		self.baseURL = baseURL
		self.accessToken = accessToken
	}

	/// Flag that indicates if the receiver has been configured correctly. If the value of this property is `false`, the
	/// `configure(for:clientID:clientSecret:)` or `configure(for:accessToken:)` methods will need to be called to
	/// configure the client for access to the Zone5 API.
	public var isConfigured: Bool {
		guard baseURL != nil else {
			return false // Always require a `baseURL`
		}

		if accessToken != nil {
			return true // Access token will happily represent the user all by itself
		}
		else if clientID != nil && clientSecret != nil {
			return true // For authentication purposes, we need a valid clientID and clientSecret
		}
		else if !requiresClientSecret {
			return true // For some hosts, we don't need a valid clientID and clientSecret
		}

		return false
	}
	
	/// Check to see whether this host requires authentication using clientID and clientSecret
	public var requiresClientSecret: Bool {
		if let server = self.baseURL, (server.host == Zone5.specializedServer || server.host == Zone5.specializedStagingServer) {
			return false
		}
		
		return true;
	}

	// MARK: Views

	/// A collection of API endpoints related to activities.
	public lazy var activities: ActivitiesView = {
		return ActivitiesView(zone5: self)
	}()

	/// A collection of API endpoints related to user authentication.
	public lazy var oAuth: OAuthView = {
		return OAuthView(zone5: self)
	}()

	/// A collection of API endpoints related to user data.
	public lazy var users: UsersView = {
		return UsersView(zone5: self)
	}()

	/// A collection of API endpoints related to routes.
	public lazy var routes: RoutesView = {
		return RoutesView(zone5: self)
	}()
	
	/// A collection of API endpoints related to metrics.
	public lazy var metrics: MetricsView = {
		return MetricsView(zone5: self)
	}()

	/// A collection of API endpoints related to third party connections (like Strava).
	public lazy var thirdPartyConnections: ThirdPartyConnectionsView = {
		return ThirdPartyConnectionsView(zone5: self)
	}()
	
	/// A collection of API endpoints related to the calling UserAgent
	public lazy var userAgents: UserAgentView = {
		return UserAgentView(zone5: self)
	}()
	
	/// A collection of API endpoints related to payments.
	public lazy var payments: PaymentsView = {
		return PaymentsView(zone5: self)
	}()
	
	/// A collection of functions to call API endpoints to a server external to Zone5
	public lazy var external: ExternalView = {
		return ExternalView(zone5: self)
	}()

	// MARK: Errors

	/// Enumeration containing the decoded value on success, or the error that occurred on failure.
	public typealias Result<Element: Decodable> = Swift.Result<Element, Zone5.Error>

	/// Function that receives a `Result` that can either contain a structure decoded from a server response, or an
	/// error if one occurred, typically used for handling the completion of an API call.
	/// - Parameter result: Enumeration containing the decoded value on success, or the error that occurred on failure.
	public typealias ResultHandler<Element: Decodable> = (_ result: Result<Element>) -> Void

	/// Definitions for errors typically thrown by Zone5 methods.
	public enum Error: Swift.Error, CustomDebugStringConvertible {

		/// An unknown error occurred.
		case unknown
		
		
		/// Invalid parameters passed to request
		case invalidParameters

		/// The Zone5 configuration is invalid. It is required that you call `configure(for:clientID:clientSecret:)`
		/// with your client details, which are included in calls to the Zone5 API.
		case invalidConfiguration

		/// A request body was provided to a request that doesn't take a request body.
		///
		/// Typically this means that the request itself is a HTTP GET request, whereas the request body suggests that
		/// the request is expected to be HTTP POST, and indicates an internal issue in the SDK.
		case unexpectedRequestBody

		/// A request body was not provided for a request that expects a request body.
		///
		/// Typically this means that the request itself is a HTTP POST request, whereas the lack of a request body
		/// suggests that the request is expected to be HTTP GET, and indicates an internal issue in the SDK.
		case missingRequestBody

		/// An error occurred while encoding the request body.
		case failedEncodingRequestBody

		/// The Zone5 server returned an error.
		///
		/// - Parameter message: The error structure returned by the server.
		case serverError(_ message: ServerMessage)

		/// An error occurred while decoding the server's response.
		///
		/// This wraps errors related to the decoder layer, and typically means that the server responded, but we
		/// weren't able to convert the response to the expected object structure, and it was also not an error message
		/// (in which case, `.serverError(_:)` would be returned instead).
		///
		/// - Parameter underlyingError: The original error thrown while decoding the response.
		case failedDecodingResponse(_ underlyingError: Swift.Error)

		/// The system produced an error while attempting to communicate with the API.
		///
		/// This typically is the source for errors related to the communication layer, i.e. server timeouts, lack of
		/// internet connection, etc. For additional information, check the `underlyingError`.
		///
		/// - Parameter underlyingError: The original error thrown while attempting to communicate with the server.
		case transportFailure(_ underlyingError: Swift.Error)

		/// Structure that represents a message produced by the server when an error occurs.
		public struct ServerMessage: Swift.Error, Codable, Equatable {

			public struct ServerError: Codable, Equatable {
				public var field: String?
				public var message: String?
				public var code: Int?
			}
			
			internal init(message: String, statusCode: Int? = nil) {
				self.message = message
				self.statusCode = statusCode
			}
			
			public let message: String
			public var reason: String?
			public var error: String?
			public var statusCode: Int?
			public var errors: [ServerError]?

            internal static let unauthorized = ServerMessage(message: "Unauthorized", statusCode: 401)

		}

		/// A textual description of the error, suitable for debugging.
		public var debugDescription: String {
			switch self {
			case .unknown: return ".unknown"
			case .invalidParameters: return ".invalidParameters"
			case .invalidConfiguration: return ".invalidConfiguration"
			case .serverError(let serverMessage): return ".serverError(statusCode: \(serverMessage.statusCode ?? 0), message: \(serverMessage.message))"
			case .unexpectedRequestBody: return ".unexpectedRequestBody"
			case .missingRequestBody: return ".missingRequestBody"
			case .failedEncodingRequestBody: return ".failedEncodingParameters"
			case .failedDecodingResponse(let underlyingError): return ".failedDecodingResponse(underlyingError: \(underlyingError.localizedDescription))"
			case .transportFailure(let underlyingError): return ".transportFailure(underlyingError: \(underlyingError.localizedDescription))"
			}
		}

	}

}
