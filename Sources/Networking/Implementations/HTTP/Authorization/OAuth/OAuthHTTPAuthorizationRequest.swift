
/// A ``HTTPRequest`` that provides OAuth tokens in its response.
///
/// Implementations should return `false` for the ``HTTPRequest/requiresAuthorization`` property.
public protocol OAuthHTTPAuthorizationRequest: HTTPRequest {
    
    // MARK: - Functions
    
    /// Extracts the Access Token from a HTTP response.
    /// - Parameter response: The response potentially containing the Access Token.
    /// - Returns: The Access Token, if available.
    func accessToken(from response: HTTPResponse<Response>) -> String?

    /// Extracts the Refresh Token from a HTTP response.
    /// - Parameter response: The response potentially containing the Refresh Token.
    /// - Returns: The Refresh Token, if available.
    func refreshToken(from response: HTTPResponse<Response>) -> String?
}
