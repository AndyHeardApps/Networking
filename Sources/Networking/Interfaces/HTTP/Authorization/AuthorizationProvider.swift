
/// Provides authorization functionality for a ``HTTPController``. Specifically the ``AuthorizingHTTPController``.
///
/// Types implementing this protocol define an ``authorize(_:)`` function to provide authorization credentials for a request. This can be done in any way, as long as it returns a ``HTTPRequest`` with the same ``HTTPRequest/ResponseType`` as the provided request.
///
/// An ``AuthorizationRequest`` type must also be defined. This is a type of ``HTTPRequest`` that implementations make use of to extract authorization credentials that are later used to authorize requests. The ``handle(authorizationResponse:from:)`` function is called by an ``AuthorizingHTTPController``, and is handed a ``HTTPResponse`` returned from an ``AuthorizationRequest`` that can be used to extract and store any required credentials.
///
/// The ``authorize(_:)`` function is called by an ``AuthorizingHTTPController`` before a request is submitted. Any previously stored credentials should be applied where possible. Only requests with ``HTTPRequest/requiresAuthorization`` equal to `true` will be handed to an ``AuthorizationProvider``.
///
/// Custom ``HTTPController`` implementations should be sure to correctly authorize requests before submission, making to only authorize requests that require it, and should correctly hand responses to the ``handle(authorizationResponse:from:)`` function.
public protocol AuthorizationProvider<AuthorizationRequest>  {
    
    /// The type of ``HTTPRequest`` that an ``AuthorizationProvider`` is able to make use of, alongside a ``HTTPResponse``, to extract authorization credentials.
    associatedtype AuthorizationRequest: HTTPRequest

    // MARK: - Functions
    
    /// Authorizes a ``HTTPRequest``.
    ///
    /// Only requests with ``HTTPRequest/requiresAuthorization`` equal to `true` should be handed to this function. Implementations should apply authorizing credentials to the request before returning it.
    /// - Parameter request: The ``HTTPRequest`` that needs to be authorized.
    /// - Returns: Any ``HTTPRequest``, with authorization credentials provided where possible.
    func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.ResponseType>
    
    /// Extracts authorization credentials from the provided ``AuthorizationRequest`` and associated ``HTTPResponse`` where possible, and stores them for later use in ``authorize(_:)``.
    /// - Parameters:
    ///   - authorizationResponse: A ``HTTPResponse``, potentially containing authorization credentials that can be extracted.
    ///   - request: The ``HTTPRequest`` that produced the `authorizationResponse`.
    func handle(
        authorizationResponse: HTTPResponse<AuthorizationRequest.ResponseType>,
        from request: AuthorizationRequest
    )    
}
