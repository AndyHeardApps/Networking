
/// A type containing OAuth authorization credentials.
public protocol OAuthAuthorizationRequestResponse {
    
    // MARK: - Properties
    
    /// The access token used to authorize OAuth requests.
    var accessToken: String { get }
    
    /// The refresh token used to reauthorize the client and fetch new tokens when an `unauthorized` `401` response is recieved.
    var refreshToken: String { get }
}
