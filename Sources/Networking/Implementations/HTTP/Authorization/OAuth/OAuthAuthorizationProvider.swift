import Foundation

/// A `ReauthorizationProvider` that implements the OAuth method of using access and refresh tokens. It makes use of the ``OAuthAuthorizationRequest`` and ``OAuthReauthorizationRequest`` types to delegate the extraction of tokens back to the API specific requests.
///
/// The `AuthorizationRequest` is usually the login request that returns access and refresh tokens, and the `ReauthorizationRequest` is usually the request that uses the refresh token to retrieve a new token pair.
///
/// Tokens are stored in the keychain by default under the keys `com.AndyHeardApps.Networking.oauthStorage.oauth.accessToken` and `com.AndyHeardApps.Networking.oauthStorage.oauth.accessToken`. They are not removed on logout.
public struct OAuthAuthorizationProvider<AuthorizationRequest, ReauthorizationRequest>
where AuthorizationRequest: OAuthAuthorizationRequest,
      ReauthorizationRequest: OAuthReauthorizationRequest
{
    
    // MARK: - Properties
    let storage: SecureStorage
    
    // MARK: - Initialisers
    init(storage: SecureStorage) {
        
        self.storage = storage
    }
    
    /// Creates a new `OAuthAuthorizationProvider` instance, using the keychain to store tokens.
    public init() {
        
        self.storage = KeychainSecureStorage(key: OAuthAuthorizationProviderStorageKey.storage)
    }
}

// MARK: - Reauthorization provider
extension OAuthAuthorizationProvider: ReauthorizationProvider {
    
    public func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard let accessToken = storage[OAuthAuthorizationProviderStorageKey.accessToken] else {
            return request
        }
        
        var headers = request.headers ?? [:]
        headers[OAuthAuthorizationProviderStorageKey.authorizationHeader] = "Bearer \(accessToken)"

        let request = AnyNetworkRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            transform: request.transform
        )
        
        return request
    }
    
    public func makeReauthorizationRequest() -> ReauthorizationRequest? {
        
        guard let refreshToken = storage[OAuthAuthorizationProviderStorageKey.refreshToken] else {
            return nil
        }
        
        return ReauthorizationRequest(refreshToken: refreshToken)
    }
    
    public func handle(
        authorizationResponse: NetworkResponse<AuthorizationRequest.ResponseType>,
        from request: AuthorizationRequest
    ) {
        
        if let newAccessToken = request.accessToken(from: authorizationResponse) {
            storage[OAuthAuthorizationProviderStorageKey.accessToken] = newAccessToken
        }
        
        if let newRefreshToken = request.refreshToken(from: authorizationResponse) {
            storage[OAuthAuthorizationProviderStorageKey.refreshToken] = newRefreshToken
        }
    }
    
    public func handle(
        reauthorizationResponse: NetworkResponse<ReauthorizationRequest.ResponseType>,
        from request: ReauthorizationRequest
    ) {
        
        if let newAccessToken = request.accessToken(from: reauthorizationResponse) {
            storage[OAuthAuthorizationProviderStorageKey.accessToken] = newAccessToken
        }
        
        if let newRefreshToken = request.refreshToken(from: reauthorizationResponse) {
            storage[OAuthAuthorizationProviderStorageKey.refreshToken] = newRefreshToken
        }
    }
}

// MARK: - Keys
enum OAuthAuthorizationProviderStorageKey {
    
    static let authorizationHeader = "Authorization"
    static let storage = "oauthStorage"
    static let accessToken = "oauth.accessToken"
    static let refreshToken = "oauth.refreshToken"
}
