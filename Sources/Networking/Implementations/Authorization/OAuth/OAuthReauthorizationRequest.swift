
/// A request type that can be constructed with a refresh token, that is then used to reauthorize the client by fetching new OAuth tokens. Implementations should return `false` for the `requiresAuthorization` property.
public protocol OAuthReauthorizationRequest: OAuthAuthorizationRequest {
    
    // MARK: - Initialisers
    
    /// Creates a new `OAuthReauthorizationRequest` with the provided `refreshToken`.
    /// - Parameters:
    ///   - refreshToken: The refresh token to be used to attempt to reauthenticate the client.
    init(refreshToken: String)
}
