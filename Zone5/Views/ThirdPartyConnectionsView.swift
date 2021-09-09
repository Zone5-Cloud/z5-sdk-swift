//
//  ThirdPartyConnectionsView.swift
//  Zone5
//
//  Created by John Covele on Oct 14, 2020.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

public class ThirdPartyConnectionsView: APIView {
	private enum Endpoints: String, InternalRequestEndpoint {
		case initializePairing = "/rest/users/connections/pair/{connectionType}"
		case confirmConnection = "/rest/files/{connectionType}/confirm"
		case userConnections = "/rest/users/connections"
		case removeThirdPartyConnection = "/rest/users/connections/rem/{connectionType}"
		case registerDeviceWithThirdParty = "/rest/users/scheduled/activities/api/v1/push_registrations"
		case deregisterDeviceWithThirdParty = "/rest/users/scheduled/activities/api/v1/push_registrations/{token}"
		
		// used internally only to configure redirect with connect.zone5cloud.com
		case temporaryToken = "/rest/auth/code"
	}
	
	/// Register a push token for a device with a 3rd party
	///- Parameters:
	/// - PushRegistration (token, platform, deviceId): Push registration for a device with a third party
	@discardableResult
	public func registerDeviceWithThirdParty(registration: PushRegistration, completion: @escaping Zone5.ResultHandler<PushRegistrationResponse>) -> PendingRequest? {
		return post(Endpoints.registerDeviceWithThirdParty, body: registration, with: completion)
	}
	
	/// Deregister a push token for a device with a 3rd party
	/// - Parameters:
	/// - token: 3rd party push token to deregister
	@discardableResult
	public func deregisterDeviceWithThirdParty(token: String, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		let endpoint = Endpoints.deregisterDeviceWithThirdParty.replacingTokens(["token": token])
		return delete(endpoint, with: completion)
	}

	/// Initialize a connection for the current user for the given 3rd party type
	/// - Parameters
	/// - type: third party to connect to. e.g. garmin | wahoo | strava
	/// - redirect: the URL that the user will be redirected back to on completion of third party authentication
	/// - Returns a reponse containing a thrid party authentication URL. Navigate to this link so the user can authenticate with the third party. On completion the user will be redirected to the passed in redirect URL
	@discardableResult
	public func initializeThirdPartyConnection(type: UserConnectionType, redirect: URL, completion: @escaping Zone5.ResultHandler<ThirdPartyInitializeResponse>) -> PendingRequest? {
		let endpoint = Endpoints.initializePairing.replacingTokens(["connectionType": type.connectionName])
		return post(endpoint, body: EmptyBody(), expectedType: ThirdPartyInitializeResponse.self) { [weak self] result in
			
			if case .success(let val) = result {
				if let self = self, let zone5 = self.zone5, let clientID = zone5.clientID, let baseURL = zone5.baseURL, let returnedUrl = URL(string: val.url), let returnedQueryParams = (returnedUrl.query != nil ? URLEncodedBody(queryString: returnedUrl.query!) : nil), let connectionServiceString = returnedQueryParams.get("redirect_uri"), let connectionServiceUrl = URL(string: connectionServiceString) {
					// request a temporary token to append to the third party connection service
					_ = self.get(Endpoints.temporaryToken, expectedType: String.self) { result2 in
						if case .success(let code) = result2 {
							let queryParams: URLEncodedBody = ["endpoint": baseURL, "code": code, "type": type.connectionName, "clientId": clientID, "redirectUrl": redirect]
							if let connectionServiceUrl = try? queryParams.appendToURL(connectionServiceUrl) {
								let returnValue = ThirdPartyInitializeResponse(url: connectionServiceUrl.absoluteString)
								completion(.success(returnValue))
							}
						} else if case .failure(let error) = result2 {
							// failed to get a temporary token
							completion(.failure(error))
						} else {
							// don't think there are any cases that are not success or failure
							completion(.failure(.unknown))
						}
					}
					
				} else {
					// didn't have sufficient information to continue
					completion(.failure(.unknown))
				}
			} else {
				completion(result)
			}
		}
	}
	
	/// Set an access token for the current user for the given 3rd party type
	/// - Parameters
	/// - type: third party to connect to
	/// - param(eter)s: when initializeThirdPartyConnection was called it was passed a redirect for the third party to call on completion of auth. Whatever the third party attached as query params to that redirect you should pass in here
	@discardableResult
	public func setThirdPartyToken(type: UserConnectionType, parameters: URLEncodedBody, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		let endpoint = Endpoints.confirmConnection.replacingTokens(["connectionType": type.connectionName])
		
		var queryItems: [URLQueryItem] = parameters.queryItems
		queryItems.append(URLQueryItem(name: "noredirect", value: "true"))
		
		let encodedParameters = URLEncodedBody(queryItems: queryItems)
		return get(endpoint, parameters: encodedParameters, expectedType: Zone5.VoidReply.self, with: completion)
	}
	
	/// Checks if a connection type is enabled or not
	/// - Parameters
	@discardableResult
	public func hasThirdPartyToken(type: UserConnectionType, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		return get(Endpoints.userConnections, parameters: nil, expectedType: [ThirdPartyResponse].self) { result in
			switch result {
			case .success(let connections):
				guard connections.first(where: { $0.type == type.connectionName && $0.enabled == true }) != nil else {
					completion(.success(false))
					return
				}
				
				completion(.success(true))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	@discardableResult
	public func removeThirdPartyToken(type: UserConnectionType, completion: @escaping Zone5.ResultHandler<Bool>) -> PendingRequest? {
		let endpoint = Endpoints.removeThirdPartyConnection.replacingTokens(["connectionType": type.connectionName])
		return get(endpoint, with: completion)
	}
}
