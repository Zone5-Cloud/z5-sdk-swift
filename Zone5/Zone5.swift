import Foundation

/// The entrance point to the rest of the API. This class encapsulates client configuration, and provides access to the
/// individual endpoints, grouped into views.
final public class Zone5 {

	/// Shared instance of the Zone5 SDK
	public static let shared = Zone5()

	/// A light wrapper of the URLSession API, which enables communication with the server endpoints.
	internal let httpClient: HTTPClient

	init(httpClient: HTTPClient = .init()) {
		self.httpClient = httpClient

		httpClient.zone5 = self
	}

	// MARK: Configuring the SDK

	/// The access token representing the currently authenticated user.
	///
	/// This property automatically captures the token returned by the server when using methods such as
	/// `OAuthView.accessToken(username:password:completion:)`, but can also be set using a token that was stored
	/// during a previous session.
	public var accessToken: AccessToken?

	/// The root URL for the server that we want to communicate with.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public private(set) var baseURL: URL?

	/// The clientID, as provided by Zone5.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public private(set) var clientID: String?

	/// The secret key, as provided by Zone5.
	/// - Note: This value can be set using the `configure(for:clientID:clientSecret:)` method.
	public private(set) var clientSecret: String?

	/// The secret key, as provided by Zone5.
	public var redirectURI: String = "https://localhost"

	/// Configures the SDK to use the application specified by the given `clientID` and `secret`.
	/// - Parameter baseURL: The API url to use.
	/// - Parameter clientID: The clientID, as provided by Zone5.
	/// - Parameter clientSecret: The secret key, as provided by Zone5.
	public func configure(for baseURL: URL, clientID: String, clientSecret: String) {
		self.baseURL = baseURL
		self.clientID = clientID
		self.clientSecret = clientSecret
	}

	/// Flag that indicates if the receiver has been configured correctly. If the value of this property is `false`, the
	/// `configure(for:,clientID:,clientSecret:)` method will need to be called to configure the client for access to
	/// the Zone5 API.
	public var isConfigured: Bool {
		return baseURL != nil && clientID != nil && clientSecret != nil
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

	// MARK: Errors

	/// Definitions for errors typically thrown by Zone5 methods.
	public enum Error: Swift.Error, CustomDebugStringConvertible {

		/// An unknown error occurred.
		case unknown

		/// The Zone5 configuration is invalid. It is required that you call `configure(for:clientID:clientSecret:)`
		/// with your client details, which are included in calls to the Zone5 API.
		case invalidConfiguration

		/// The method called requires a user's access token for authorization, you will need to use one of the
		/// provided methods of authentication to retrieve one, or provide a previously gathered token.
		case requiresAccessToken

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
		public struct ServerMessage: Swift.Error, Codable {

			public let message: String

		}

		/// A textual description of the error, suitable for debugging.
		public var debugDescription: String {
			switch self {
			case .unknown: return ".unknown"
			case .invalidConfiguration: return ".invalidConfiguration"
			case .requiresAccessToken: return ".requiresAccessToken"
			case .serverError(let serverMessage): return ".serverError(message: \(serverMessage.message))"
			case .unexpectedRequestBody: return ".unexpectedRequestBody"
			case .missingRequestBody: return ".missingRequestBody"
			case .failedEncodingRequestBody: return ".failedEncodingParameters"
			case .failedDecodingResponse(let underlyingError): return ".failedDecodingResponse(underlyingError: \(underlyingError.localizedDescription))"
			case .transportFailure(let underlyingError): return ".transportFailure(underlyingError: \(underlyingError.localizedDescription))"
			}
		}

	}

}
