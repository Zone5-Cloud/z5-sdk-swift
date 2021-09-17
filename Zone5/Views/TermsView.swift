import Foundation

public class TermsView: APIView {

	internal enum Endpoints: String, InternalRequestEndpoint {
		case requiredTerms = "/rest/auth/terms/required"
		case acceptTerms = "/rest/auth/terms/accept/{termsID}"
		case downloadTerms = "/rest/auth/terms/download/{termsID}"
		
		var requiresAccessToken: Bool {
			switch self {
				case .requiredTerms: return false
				case .downloadTerms: return false
				default: return true
			}
		}
	}
	
	/// Get the list of required terms for the currently configured clientID. This is an unauthenticated endpoint and can be called before logging in.
	public func getRequiredTerms(completion: @escaping Zone5.ResultHandler<[TermsAndConditions]>) -> PendingRequest? {
		return get(Endpoints.requiredTerms, with: completion)
	}
	
	/// Accept the passed in terms for the current user. This is an authenticated call, pass accept list into register or login for unauthenticated acceptance.
	/// The purpose of this call is to accept updated versions or already accepted terms. For instance if after a login the login is successful but the LoginResponse
	/// contains updated terms.
	public func acceptTerms(termsID: String, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		return post(Endpoints.acceptTerms.replacingTokens(["termsID": termsID]), body: nil, with: completion)
	}
	
	/// Download the content of the passed in terms - if the terms contain content. Some terms are merely a url to external content. This is an unauthenticated endpoint.
	/// The terms must be required by the currently configured ClientID.
	public func downloadTerms(termsID: String, completion: @escaping Zone5.ResultHandler<Zone5.VoidReply>) -> PendingRequest? {
		return get(Endpoints.acceptTerms.replacingTokens(["termsID": termsID]), with: completion)
	}
}
