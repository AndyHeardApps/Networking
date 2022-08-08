
/// A `NetworkRequest` that provides OAuth credentials in it's response.
public protocol OAuthAuthorizationRequest: NetworkRequest {
    
    /// Extracts the Access Token from a network response.
    /// - Parameter response: The response potentially containing the Access Token.
    /// - Returns: The Access Token, if available.
    func accessToken(from response: NetworkResponse<ResponseType>) -> String?
    
    /// Extracts the Refresh Token from a network response.
    /// - Parameter response: The response potentially containing the Refresh Token.
    /// - Returns: The Refresh Token, if available.
    func refreshToken(from response: NetworkResponse<ResponseType>) -> String?
}

extension OAuthAuthorizationRequest {
    
    public var requiresAuthorization: Bool {
        false
    }
}
