
public protocol OAuthReauthorizationRequest: OAuthAuthorizationRequest {
    
    // MARK: - Initialisers
    
    init(refreshToken: String)
}
