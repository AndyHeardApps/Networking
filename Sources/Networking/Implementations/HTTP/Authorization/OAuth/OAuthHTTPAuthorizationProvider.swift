import Foundation

/// A `HTTPReauthorizationProvider` that implements the OAuth method of using access and refresh tokens. It makes use of the ``OAuthHTTPAuthorizationRequest`` and ``OAuthHTTPReauthorizationRequest`` types to delegate the extraction of tokens back to the API specific requests.
///
/// The `AuthorizationRequest` is usually the login request that returns access and refresh tokens, and the `ReauthorizationRequest` is usually the request that uses the refresh token to retrieve a new token pair.
///
/// Tokens are stored in the keychain by default under the keys `com.AndyHeardApps.Networking.oauthStorage.oauth.accessToken` and `com.AndyHeardApps.Networking.oauthStorage.oauth.accessToken`. They are not removed on logout.
public struct OAuthHTTPAuthorizationProvider<AuthorizationRequest, ReauthorizationRequest>
where AuthorizationRequest: OAuthHTTPAuthorizationRequest,
      ReauthorizationRequest: OAuthHTTPReauthorizationRequest
{
    
    // MARK: - Properties
    let storage: SecureStorage
    
    // MARK: - Initialisers
    init(storage: SecureStorage) {
        
        self.storage = storage
    }
    
    #if canImport(Security)
    /// Creates a new ``OAuthHTTPAuthorizationProvider`` instance, using the keychain to store tokens.
    public init() {
        
        self.storage = KeychainSecureStorage()
    }
    #endif
}

// MARK: - HTTP Reauthorization provider
extension OAuthHTTPAuthorizationProvider: HTTPReauthorizationProvider {
    
    public func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.Body, Request.Response> {
        
        guard
            request.requiresAuthorization,
            let accessToken = storage[OAuthHTTPAuthorizationProviderStorageKey.accessToken]
        else {
            return request
        }
        
        var headers = request.headers ?? [:]
        headers[OAuthHTTPAuthorizationProviderStorageKey.authorizationHeader] = "Bearer \(accessToken)"

        let request = AnyHTTPRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            encode: request.encode,
            decode: request.decode
        )
        
        return request
    }
    
    public func makeReauthorizationRequest() -> ReauthorizationRequest? {
        
        guard let refreshToken = storage[OAuthHTTPAuthorizationProviderStorageKey.refreshToken] else {
            return nil
        }
        
        return ReauthorizationRequest(refreshToken: refreshToken)
    }
    
    public func handle(
        authorizationResponse: HTTPResponse<AuthorizationRequest.Response>,
        from request: AuthorizationRequest
    ) {
        
        if let newAccessToken = request.accessToken(from: authorizationResponse) {
            storage[OAuthHTTPAuthorizationProviderStorageKey.accessToken] = newAccessToken
        }
        
        if let newRefreshToken = request.refreshToken(from: authorizationResponse) {
            storage[OAuthHTTPAuthorizationProviderStorageKey.refreshToken] = newRefreshToken
        }
    }
    
    public func handle(
        reauthorizationResponse: HTTPResponse<ReauthorizationRequest.Response>,
        from request: ReauthorizationRequest
    ) {
        
        if let newAccessToken = request.accessToken(from: reauthorizationResponse) {
            storage[OAuthHTTPAuthorizationProviderStorageKey.accessToken] = newAccessToken
        }
        
        if let newRefreshToken = request.refreshToken(from: reauthorizationResponse) {
            storage[OAuthHTTPAuthorizationProviderStorageKey.refreshToken] = newRefreshToken
        }
    }
}

// MARK: - Keys
enum OAuthHTTPAuthorizationProviderStorageKey {
    
    static let authorizationHeader = "Authorization"
    static let accessToken = "oauth.accessToken"
    static let refreshToken = "oauth.refreshToken"
}
