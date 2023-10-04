
/// Provides authorization functionality for a ``HTTPController``. Specifically the ``AuthorizingHTTPController``.
///
/// Types implementing this protocol define an ``authorize(_:)`` function to provide authorization credentials for a request. This can be done in any way, as long as it returns a ``NetworkRequest`` with the same ``NetworkRequest/ResponseType`` as the provided request.
///
/// An ``AuthorizationRequest`` type must also be defined. This is a type of ``NetworkRequest`` that implementations make use of to extract authorization credentials that are later used to authorize requests. The ``handle(authorizationResponse:from:)`` function is called by an ``AuthorizingHTTPController``, and is handed a ``NetworkResponse`` returned from an ``AuthorizationRequest`` that can be used to extract and store any required credentials.
///
/// The ``authorize(_:)`` function is called by an ``AuthorizingHTTPController`` before a request is submitted. Any previously stored credentials should be applied where possible. Only requests with ``NetworkRequest/requiresAuthorization`` equal to `true` will be handed to an ``AuthorizationProvider``.
///
/// Custom ``HTTPController`` implementations should be sure to correctly authorize requests before submission, making to only authorize requests that require it, and should correctly hand responses to the ``handle(authorizationResponse:from:)`` function.
public protocol AuthorizationProvider<AuthorizationRequest>  {
    
    /// The type of ``NetworkRequest`` that an ``AuthorizationProvider`` is able to make use of, alongside a ``NetworkResponse``, to extract authorization credentials.
    associatedtype AuthorizationRequest: NetworkRequest

    // MARK: - Functions
    
    /// Authorizes a ``NetworkRequest``.
    ///
    /// Only requests with ``NetworkRequest/requiresAuthorization`` equal to `true` should be handed to this function. Implementations should apply authorizing credentials to the request before returning it.
    /// - Parameter request: The ``NetworkRequest`` that needs to be authorized.
    /// - Returns: Any ``NetworkRequest``, with authorization credentials provided where possible.
    func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType>
    
    /// Extracts authorization credentials from the provided ``AuthorizationRequest`` and associated ``NetworkResponse`` where possible, and stores them for later use in ``authorize(_:)``.
    /// - Parameters:
    ///   - authorizationResponse: A ``NetworkResponse``, potentially containing authorization credentials that can be extracted.
    ///   - request: The ``NetworkRequest`` that produced the `authorizationResponse`.
    func handle(
        authorizationResponse: NetworkResponse<AuthorizationRequest.ResponseType>,
        from request: AuthorizationRequest
    )    
}
