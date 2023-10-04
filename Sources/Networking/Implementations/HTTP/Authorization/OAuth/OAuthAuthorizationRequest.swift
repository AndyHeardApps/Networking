
/// A ``HTTPRequest`` that provides OAuth tokens in its response.
///
/// Implementations should return `false` for the ``requiresAuthorization`` property.
public protocol OAuthAuthorizationRequest: HTTPRequest {
    
    // MARK: - Functions
    
    /// Extracts the Access Token from a network response.
    /// - Parameter response: The response potentially containing the Access Token.
    /// - Returns: The Access Token, if available.
    func accessToken(from response: HTTPResponse<ResponseType>) -> String?

    /// Extracts the Refresh Token from a network response.
    /// - Parameter response: The response potentially containing the Refresh Token.
    /// - Returns: The Refresh Token, if available.
    func refreshToken(from response: HTTPResponse<ResponseType>) -> String?
}

extension OAuthAuthorizationRequest {
    
    public var requiresAuthorization: Bool {
        false
    }
}
