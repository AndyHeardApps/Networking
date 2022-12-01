
public protocol OAuthAuthorizationRequest: NetworkRequest {
    
    // MARK: - Functions
    func accessToken(from response: NetworkResponse<ResponseType>) -> String?

    func refreshToken(from response: NetworkResponse<ResponseType>) -> String?
}

extension OAuthAuthorizationRequest {
    
    public var requiresAuthorization: Bool {
        false
    }
}
