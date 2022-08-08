
/// An `AuthorizationProvider` that performs no work, and no authorization.
public struct EmptyAuthorizationProvider: AuthorizationProvider {

    public func makeReauthorizationRequest() -> AnyRequest<Void>? {
        nil
    }
    
    public func handle(authorizationResponse: NetworkResponse<()>, from request: AnyRequest<Void>) {}
    public func handle(reauthorizationResponse: NetworkResponse<()>, from request: AnyRequest<Void>) {}
    
    public func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType> {
        request
    }
}
