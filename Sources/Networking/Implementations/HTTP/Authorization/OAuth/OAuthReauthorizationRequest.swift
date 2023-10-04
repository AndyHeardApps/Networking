
/// A request type that can be constructed with a refresh token, that is then used to reauthorize the client by fetching new OAuth tokens.
///
/// Implementations should return `false` for the ``NetworkRequest/requiresAuthorization`` property.
public protocol OAuthReauthorizationRequest: OAuthAuthorizationRequest {
    
    // MARK: - Initialisers
    
    /// Creates a new request from the provided `refreshToken`.
    /// - Parameter refreshToken: The refresh token to be used in the reauthorizing request.
    init(refreshToken: String)
}
