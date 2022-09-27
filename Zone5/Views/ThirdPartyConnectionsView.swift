//
//  ThirdPartyConnectionsView.swift
//  Zone5
//
//  Created by John Covele on Oct 14, 2020.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation
import UIKit

public class ThirdPartyConnectionsView: APIView {
	private enum Endpoints: String, InternalRequestEndpoint {
		case initializePairing = "/rest/users/connections/pair/{connectionType}"
		case confirmConnection = "/rest/files/{connectionType}/confirm"
		case connectService = "/rest/users/connections/service/{connectionType}"
		case userConnections = "/rest/users/connections"
		case removeThirdPartyConnection = "/rest/users/connections/rem/{connectionType}"
		case registerDeviceWithThirdParty = "/rest/users/scheduled/activities/api/v1/push_registrations"
		case deregisterDeviceWithThirdParty = "/rest/users/scheduled/activities/api/v1/push_registrations/{token}"
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

	@discardableResult
	@available(*, deprecated, message: "Use `pairThirdPartyConnection(type:redirect:completion)` instead.")
	public func initializeThirdPartyConnection(type: UserConnectionType, completion: @escaping Zone5.ResultHandler<ThirdPartyInitializeResponse>) -> PendingRequest? {
		let endpoint = Endpoints.initializePairing.replacingTokens(["connectionType": type.connectionName])
		return post(endpoint, body: EmptyBody(), with: completion)
	}

	@discardableResult
	@available(*, deprecated, message: "Use `pairThirdPartyConnection(type:redirect:completion)` instead.")
	public func setThirdPartyToken(type: UserConnectionType, parameters: URLEncodedBody, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		let endpoint = Endpoints.confirmConnection.replacingTokens(["connectionType": type.connectionName])
		
		var queryItems: [URLQueryItem] = parameters.queryItems
		queryItems.append(URLQueryItem(name: "noredirect", value: "true"))
		
		let encodedParameters = URLEncodedBody(queryItems: queryItems)
		return get(endpoint, parameters: encodedParameters, expectedType: Zone5.VoidReply.self, with: completion)
	}
	
	/// pair a connection for the current user for the given 3rd party type
	/// - Parameters
	/// - type: third party to connect to. e.g. garminconnect | garmintraining | wahoo | strava
	/// - redirect: the URL that the user will be redirected back to on completion of third party authentication
	/// - Returns a reponse containing a thrid party authentication URL. Open this link in a browser so the user can authenticate with the third party. On completion the user will be redirected back to the passed in redirect URL
	@discardableResult
	@available(iOSApplicationExtension, unavailable)
	public func pairThirdPartyConnection(type: UserConnectionType, redirect: URL, completion: @escaping Zone5.ResultHandler<String>) -> PendingRequest? {
		let endpoint = Endpoints.connectService.replacingTokens(["connectionType": type.connectionName])
		
		if type == .strava, UIApplication.shared.canOpenURL(URL(string: "strava://")!) {
			return get(endpoint, parameters: ["redirect-uri": redirect.absoluteString, "platform": "ios"], with: completion)
		} else {
			return get(endpoint, parameters: ["redirect-uri": redirect.absoluteString], with: completion)
		}
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
	
	/// Returns list of connected third party types
	/// - Parameters
	@discardableResult
	public func enabledThirdPartyConnections(completion: @escaping Zone5.ResultHandler<[UserConnectionType]>) -> PendingRequest? {
		return get(Endpoints.userConnections, parameters: nil, expectedType: [ThirdPartyResponse].self) { result in
			switch result {
			case .success(let connections):
				let connectedTypes: [UserConnectionType] = UserConnectionType.allCases.filter({ t in connections.first(where: { $0.type == t.connectionName && $0.enabled }) != nil })
				completion(.success(connectedTypes))
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
