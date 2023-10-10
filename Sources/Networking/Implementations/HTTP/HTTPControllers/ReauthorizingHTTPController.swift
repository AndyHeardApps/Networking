import Foundation

/// A ``HTTPController`` that authorizes every request submitted using the provided ``HTTPReauthorizationProvider``, and attempts to reauthorize the app whenever authorization fails.
///
/// This type extends the authorizing behavior of the ``AuthorizingHTTPController``, so refer to its documentation for authorization details.
///
/// This difference between ``AuthorizingHTTPController`` and ``ReauthorizingHTTPController`` is that the ``delegate`` is a ``ReauthorizingHTTPControllerDelegate`` that has the additional ``ReauthorizingHTTPControllerDelegate/controller(_:shouldAttemptReauthorizationAfterCatching:from:)`` function that decides whether a thrown error can be recovered by reauthorizing and resubmitting the request. In addition, the ``authorization`` is a ``HTTPReauthorizationProvider``, that provides the ``HTTPReauthorizationProvider/makeReauthorizationRequest()`` and ``HTTPReauthorizationProvider/handle(reauthorizationResponse:from:)`` functions for creating reauthorizing requests and handling their responses.
///
/// As with the ``AuthorizingHTTPController``, requests are handed to the ``HTTPAuthorizationProvider/authorize(_:)`` function before they are submitted, and instances of ``HTTPAuthorizationProvider/AuthorizationRequest`` and assocated ``HTTPResponse`` from successful requests are passed to the ``HTTPAuthorizationProvider/handle(authorizationResponse:from:)`` function.
///
/// If the requests ``HTTPRequest/decode(data:statusCode:using:)`` function throws an error, the error is passed to the ``ReauthorizingHTTPControllerDelegate/controller(_:shouldAttemptReauthorizationAfterCatching:from:)`` function. If it returns `true` then the ``HTTPReauthorizationProvider/makeReauthorizationRequest()`` function is used to create and submit a reauthorizing request. The initial failed request then has the updated credentials added to it and is resubmitted. If the ``delegate`` is `nil`, then this same logic is applied for a ``HTTPStatusCode/unauthorized`` status code by default.
public struct ReauthorizingHTTPController<Authorization: HTTPReauthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to (other than potentially reauthorization requests). This is the base `URL` used to construct the full `URL` using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The base `URL` to submit any reauthorization requests to. This may be some separate auth microservice. As with `baseURL` the full `URL` for a request is constructed  using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let reauthorizationBaseURL: URL
    
    /// The ``HTTPSession`` used to fetch the raw `Data` ``HTTPResponse`` for a request.
    public let session: HTTPSession
    
    /// A collection of ``DataEncoder`` and ``DataDecoder`` objects that the controller will use to encode and decode specific HTTP content types.
    public let dataCoders: DataCoders
    
    /// The delegate used to provide additional controler over preparing a request to be sent, handling responses, and handling errors.
    public let delegate: ReauthorizingHTTPControllerDelegate
    
    /// The ``HTTPReauthorizationProvider`` used to authorize requests that need it, and reauthorize the app whenever possible.
    public let authorization: Authorization
        
    // MARK: - Initialisers

    /// Creates a new ``ReauthorizingHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - reauthorizationBaseURL: The `URL` used to reauthorize the controller. If `nil`, then the `baseURL` is set instead.
    ///   - dataCoders: The ``DataCoders`` that can be used to encode and decode request body and responses. By default, only JSON coders will be available.
    ///   - delegate: The ``HTTPControllerDelegate`` for the controller to use. If none is provided, then a default implementation is used to provide standard functionality.
    ///   - session: The ``HTTPSession`` the controller will use.
    ///   - authorization: The ``HTTPReauthorizationProvider`` to use to authorize requests.
    public init(
        baseURL: URL,
        reauthorizationBaseURL: URL? = nil,
        session: HTTPSession = URLSession.shared,
        dataCoders: DataCoders,
        delegate: ReauthorizingHTTPControllerDelegate? = nil,
        authorization: Authorization
    ) {
        
        self.baseURL = baseURL
        self.reauthorizationBaseURL = reauthorizationBaseURL ?? baseURL
        self.session = session
        self.dataCoders = dataCoders
        self.delegate = delegate ?? DefaultReauthorizingHTTPControllerDelegate()
        self.authorization = authorization
    }
}

// MARK: - HTTP controller
extension ReauthorizingHTTPController: HTTPController {
    
    public func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.Response> {
        
        try await fetchResponse(
            request,
            shouldAttemptReauthorization: true
        )
    }
    
    private func fetchResponse<Request: HTTPRequest>(
        _ request: Request,
        shouldAttemptReauthorization: Bool
    ) async throws -> HTTPResponse<Request.Response> {

        let authorizedRequest = try authorize(request: request)
        let rawDataRequest = try delegate.controller(
            self,
            prepareRequestForSubmission: authorizedRequest,
            using: dataCoders
        )

        // Errors thrown here cannot be fixed with reauth
        let dataResponse = try await session.submit(
            request: rawDataRequest,
            to: baseURL
        )
        
        do {
            let response = try delegate.controller(
                self,
                decodeResponse: dataResponse,
                fromRequest: request,
                using: dataCoders
            )
            
            extractAuthorizationContent(
                from: response,
                returnedBy: request
            )
            
            return response
            
        } catch {
            
            guard
                shouldAttemptReauthorization,
                delegate.controller(
                    self,
                    shouldAttemptReauthorizationAfterCatching: error,
                    from: dataResponse
                ) 
            else {
                throw delegate.controller(
                    self,
                    didRecieveError: error,
                    from: dataResponse,
                    using: dataCoders
                )
            }
            
            try await reauthorize(
                afterError: error,
                from: dataResponse
            )
            
            let response = try await fetchResponse(
                request,
                shouldAttemptReauthorization: false
            )
            
            return response
        }
    }
}

// MARK: - Request modification
extension ReauthorizingHTTPController {
    
    private func authorize<Request: HTTPRequest>(request: Request) throws -> any HTTPRequest<Request.Body, Request.Response> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = try authorization.authorize(request)
        
        return authorizedRequest
    }
}

// MARK: - Reauthorization
extension ReauthorizingHTTPController {
    
    private func reauthorize(
        afterError originalError: Error,
        from originalResponse: HTTPResponse<Data>
    ) async throws {
        
        do {
            guard
                let reauthorizationRequest = authorization.makeReauthorizationRequest(),
                !reauthorizationRequest.requiresAuthorization
            else {
                throw originalError
            }
            
            let rawDataRequest = try delegate.controller(
                self,
                prepareRequestForSubmission: reauthorizationRequest,
                using: dataCoders
            )
            
            let dataResponse = try await session.submit(
                request: rawDataRequest,
                to: reauthorizationBaseURL
            )
            
            let reauthorizationResponse = try delegate.controller(
                self,
                decodeResponse: dataResponse,
                fromRequest: reauthorizationRequest,
                using: dataCoders
            )
            
            extractAuthorizationContent(
                from: reauthorizationResponse,
                returnedBy: reauthorizationRequest
            )
            
        } catch {
            
            let mappedError = delegate.controller(
                self,
                didRecieveError: originalError,
                from: originalResponse,
                using: dataCoders
            )

            throw mappedError
            
        }
    }
}

// MARK: - Authorized content extraction
extension ReauthorizingHTTPController {
    
    private func extractAuthorizationContent<Response>(
        from response: HTTPResponse<Response>,
        returnedBy request: some HTTPRequest
    ) {
        
        if
            let authorizationRequest = request as? Authorization.AuthorizationRequest,
            let authorizationResponse = response as? HTTPResponse<Authorization.AuthorizationRequest.Response>
        {
            authorization.handle(
                authorizationResponse: authorizationResponse,
                from: authorizationRequest
            )
        }
        
        if
            let reauthorizationRequest = request as? Authorization.ReauthorizationRequest,
            let reauthorizationResponse = response as? HTTPResponse<Authorization.ReauthorizationRequest.Response>
        {
            authorization.handle(
                reauthorizationResponse: reauthorizationResponse,
                from: reauthorizationRequest
            )
        }
    }
}
