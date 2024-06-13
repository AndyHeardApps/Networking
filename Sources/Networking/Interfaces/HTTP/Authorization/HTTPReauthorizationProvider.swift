
/// Extends the authorizing capabilities of a ``HTTPAuthorizationProvider`` with functions to facilitate reauthorization when needed.
///
/// The ``ReauthorizationRequest`` type is some ``HTTPRequest`` that can be used to reauthorize the app with the server. It should be made with existing, stored credentials where possible, and if it cannot be made, and `nil` is returned, then reauthorization is abandonded.
///
/// As with ``HTTPAuthorizationProvider/handle(authorizationResponse:from:)``, the ``handle(reauthorizationResponse:from:)`` function is called by a ``ReauthorizingHTTPController`` when a ``ReauthorizationRequest`` is successfully sent and a response returned. The contents of the request and response should be used to extract and store any credentials required by future ``HTTPAuthorizationProvider/authorize(_:)`` or ``makeReauthorizationRequest()`` calls.
///
/// The ``makeReauthorizationRequest()`` function is also called by a ``ReauthorizingHTTPController`` when its ``ReauthorizingHTTPController/delegate`` returns `true` from ``ReauthorizingHTTPControllerDelegate/controller(_:shouldAttemptReauthorizationAfterCatching:from:)``. If the ``ReauthorizingHTTPController/delegate`` handed to the initialiser is `nil`, then it is called when an ``HTTPStatusCode/unauthorized`` status code is returned by a request.
public protocol HTTPReauthorizationProvider<AuthorizationRequest, ReauthorizationRequest>: HTTPAuthorizationProvider {
    
    /// A type of ``HTTPRequest`` that a ``HTTPReauthorizationProvider`` is able to create to reauthorize the app with an API.
    associatedtype ReauthorizationRequest: HTTPRequest

    // MARK: - Functions
    
    /// Makes a request that can be used to reauthorize the app with an API.
    ///
    /// This function is called by an ``AuthorizingHTTPController`` when its ``ReauthorizingHTTPController/delegate`` prompts it to reauthorize, or if no delegat is provided, when an ``HTTPStatusCode/unauthorized`` status code is returned by a request. If the credentials to create a request are not available, then return `nil` in order to abandon the reauthorization process.
    /// - Returns: A request that can be used to reauthorize the app with an API, or `nil` if the request cannot be constructed.
    func makeReauthorizationRequest() async -> ReauthorizationRequest?

    /// Extracts authorization credentials from the provided <doc:/documentation/Networking/HTTPReauthorizationProvider/ReauthorizationRequest> and associated ``HTTPResponse`` where possible, and stores them for later use in ``HTTPAuthorizationProvider/authorize(_:)`` and ``makeReauthorizationRequest()``.
    /// - Parameters:
    ///   - reauthorizationResponse: A ``HTTPResponse``, potentially containing authorization credentials that can be extracted.
    ///   - request: The ``HTTPRequest`` that produced the `reauthorizationResponse`.
    func handle(
        reauthorizationResponse: HTTPResponse<ReauthorizationRequest.Response>,
        from request: ReauthorizationRequest
    ) async
}
