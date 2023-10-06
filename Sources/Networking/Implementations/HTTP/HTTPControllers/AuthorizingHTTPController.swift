import Foundation

/// A ``HTTPController`` that authorizes every request submitted using the provided ``HTTPAuthorizationProvider``.
///
/// This type extends the basic implementation of the ``BasicHTTPController``, so refer to its documentation for basic usage.
///
/// This difference between ``BasicHTTPController`` and ``AuthorizingHTTPController`` is that every request submitted through this type with ``HTTPRequest/requiresAuthorization`` equal to `true` will try and have authorizing credentials attached using the provided ``HTTPAuthorizationProvider`` before it is submitted.
///
/// Requests are handed to the ``HTTPAuthorizationProvider/authorize(_:)`` function before they are submitted, and instances of ``HTTPAuthorizationProvider/AuthorizationRequest`` and assocated ``HTTPResponse`` from successful requests are passed to the ``HTTPAuthorizationProvider/handle(authorizationResponse:from:)`` function.
public struct AuthorizingHTTPController<Authorization: HTTPAuthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``HTTPSession`` used to fetch the raw `Data` ``HTTPResponse`` for a request.
    public let session: HTTPSession
    
    public let dataCoders: DataCoders
    
    public let delegate: HTTPControllerDelegate
        
    /// The ``HTTPAuthorizationProvider`` used to authorize requests that need it.
    public let authorization: Authorization
    
    // MARK: - Initialisers

    /// Creates a new ``AuthorizingHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``HTTPSession`` the controller will use.
    ///   - authorization: The ``HTTPAuthorizationProvider`` to use to authorize requests.
    ///   - decoder: The ``DataDecoder`` the controller will hand to requests for decoding.
    ///   - errorHandler: The ``HTTPErrorHandler`` that can be used to manipulate errors before they are thrown.
    ///   - universalHeaders: The headers applied to every request submitted.
    public init(
        baseURL: URL,
        session: HTTPSession = URLSession.shared,
        dataCoders: DataCoders,
        delegate: HTTPControllerDelegate? = nil,
        authorization: Authorization
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.dataCoders = dataCoders
        self.delegate = delegate ?? DefaultHTTPControllerDelegate()
        self.authorization = authorization
    }
}

// MARK: - HTTP controller
extension AuthorizingHTTPController: HTTPController {
    
    public func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.Response> {
        
        let authorizedRequest = try authorize(request: request)
        let rawDataRequest = try delegate.controller(
            self,
            prepareRequestForSubmission: authorizedRequest,
            using: dataCoders
        )

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
            
            let mappedError = delegate.controller(
                self,
                didRecieveError: error,
                from: dataResponse
            )

            throw mappedError
        }
    }
}

// MARK: - Request modification
extension AuthorizingHTTPController {
    
    private func authorize<Request: HTTPRequest>(request: Request) throws -> any HTTPRequest<Request.Body, Request.Response> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = try authorization.authorize(request)
        
        return authorizedRequest
    }
}
    
// MARK: - Authorized content extraction
extension AuthorizingHTTPController {
    
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
    }
}
