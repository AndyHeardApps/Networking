
/// Provides authorization for requests. Implementations should be able to accept a request, and use its contents to return an authorizedversion of that request as an `AnyRequest`. It also has the option of providing a `ReauthorizationRequest` which is automatically used by the `NetworkController` when an `unauthorized` `401` response code is received to try and reauthorize and retry the failed request. Implementations should also be able to accept the `ResponseTypes` from an `AuthorizationRequest` and a `ReauthorizationRequest` and extract and store any authorization credentials from them for later use in the `authorize(_ request: )` function. Any `ReauthorizationRequest` should have `requiresAuthorization` equal to `false` in order to be usable.
public protocol AuthorizationProvider {
    
    /// A request type that can be used to initially authorize the client.
    associatedtype AuthorizationRequest: NetworkRequest
    
    /// A request type that can be use to reauthorize the client automatically.
    associatedtype ReauthorizationRequest: NetworkRequest
    
    // MARK: - Functions
    
    /// Creates and returns a request that can be used to reauthorize the client when an `unauthorized` `401` status code is recieved. If `nil` is returned, reauthorization is not attempted.
    /// - Returns: A reauthorization request.
    func makeReauthorizationRequest() -> ReauthorizationRequest?
    
    /// Implementations should extract and store authorization credentials from the provided response for use in later request authorization. This is called by the `NetworkController` when an `AuthorizationRequest` is submitted and a response recieved.
    /// - Parameters:
    ///   - authorizationResponse: The `NetworkResponse` that should be used to extract authorization credentials.
    ///   - request: The request that procured the response.
    func handle(authorizationResponse: NetworkResponse<AuthorizationRequest.ResponseType>, from request: AuthorizationRequest)
    
    /// Implementations should extract and store authorization credentials from the provided response for use in later request authorization. This is called by the `NetworkController` when a `ReauthorizationRequest` is submitted and a response recieved.
    /// - Parameters:
    ///   - reauthorizationResponse: The `NetworkResponse` that should be used to extract authorization credentials.
    ///   - request: The request that procured the response.
    func handle(reauthorizationResponse: NetworkResponse<ReauthorizationRequest.ResponseType>, from request: ReauthorizationRequest)
    
    /// Implementations should use the details of the provided request and use them to construct an authorized request.
    /// - Parameters:
    ///   - request: The `NetworkRequest` that needs authorizing.
    /// - Returns: An authorized version of the network request.
    func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType>
}
