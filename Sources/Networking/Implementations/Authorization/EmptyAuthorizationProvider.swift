
/// An `AuthorizationProvider` that performs no work, and no authorization.
public struct EmptyAuthorizationProvider: AuthorizationProvider {
    
    public typealias AuthorizationRequest = AnyRequest<Void>
    public typealias ReauthorizationRequest = AnyRequest<Void>
    
    public func makeReauthorizationRequest() -> AnyRequest<Void>? {
        nil
    }
    
    public func handle(authorizationResponse: NetworkResponse<()>) {}
    
    public func handle(reauthorizationResponse: NetworkResponse<()>) {}
    
    public func authorize<Request: NetworkRequest>(_ request: Request) -> AnyRequest<Request.ResponseType> {
        
        AnyRequest(request)
    }
}
