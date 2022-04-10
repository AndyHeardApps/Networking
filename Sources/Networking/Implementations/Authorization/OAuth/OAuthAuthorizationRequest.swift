
/// A `NetworkRequest` that returns OAuth credentials in it's response type.
public protocol OAuthAuthorizationRequest: NetworkRequest where Self.ResponseType: OAuthAuthorizationRequestResponse {}
