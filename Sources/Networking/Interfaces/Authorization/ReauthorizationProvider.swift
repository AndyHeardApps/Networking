
/// Extends the authorizing capabilities of a ``AuthorizationProvider`` with functions to facilitate reauthorization when needed.
///
/// The ``ReauthorizationRequest`` type is some ``NetworkRequest`` that can be used to reauthorize the app with the server. It should be made with existing, stored credentials where possible, and if it cannot be made, and `nil` is returned, then reauthorization is abandonded.
///
/// As with ``AuthorizationProvider/handle(authorizationResponse:from:)``, the ``handle(reauthorizationResponse:from:)`` function is called by a ``ReauthorizingNetworkController`` when a ``ReauthorizationRequest`` is successfully sent and a response returned. The contents of the request and response should be used to extract and store any credentials required by future ``AuthorizationProvider/authorize(_:)`` or ``makeReauthorizationRequest()`` calls.
///
/// The ``makeReauthorizationRequest()`` function is also called by a ``ReauthorizingNetworkController`` when its ``ReauthorizingNetworkController/errorHandler`` returns `true` from ``ReauthorizationNetworkErrorHandler/shouldAttemptReauthorization(afterCatching:from:)``. If the ``ReauthorizingNetworkController/errorHandler`` is `nil`, then it is called when an ``HTTPStatusCode/unauthorized`` status code is returned by a request.
public protocol ReauthorizationProvider<AuthorizationRequest, ReauthorizationRequest>: AuthorizationProvider {
    
    /// A type of ``NetworkRequest`` that a ``ReauthorizationProvider`` is able to create to reauthorize the app with an API.
    associatedtype ReauthorizationRequest: NetworkRequest

    // MARK: - Functions
    
    /// Makes a request that can be used to reauthorize the app with an API.
    ///
    /// This function is called by an ``AuthorizingNetworkController`` when its ``ReauthorizingNetworkController/errorHandler`` prompts it to reauthorize, or if the error handler is `nil`, when an ``HTTPStatusCode/unauthorized`` status code is returned by a request. If the credentials to create a request are not available, then return `nil` in order to abandon the reauthorization process.
    /// - Returns: A request that can be used to reauthorize the app with an API, or nil if the request cannot be made.
    func makeReauthorizationRequest() -> ReauthorizationRequest?
        
    /// Extracts authorization credentials from the provided ``ReauthorizationRequest`` and associated ``NetworkResponse`` where possible, and stores them for later use in ``AuthorizationProvider/authorize(_:)`` and ``makeReauthorizationRequest()``.
    /// - Parameters:
    ///   - reauthorizationResponse: A ``NetworkResponse``, potentially containing authorization credentials that can be extracted.
    ///   - request: The ``NetworkRequest`` that produced the `reauthorizationResponse`.
    func handle(reauthorizationResponse: NetworkResponse<ReauthorizationRequest.ResponseType>, from request: ReauthorizationRequest)
}
