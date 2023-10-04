import Foundation

/// A ``HTTPController`` that authorizes every request submitted using the provided ``AuthorizationProvider``.
///
/// This type extends the basic implementation of the ``BasicHTTPController``, so refer to its documentation for basic usage.
///
/// This difference between ``BasicHTTPController`` and ``AuthorizingHTTPController`` is that every request submitted through this type with ``HTTPRequest/requiresAuthorization`` equal to `true` will try and have authorizing credentials attached using the provided ``AuthorizationProvider`` before it is submitted.
///
/// Requests are handed to the ``AuthorizationProvider/authorize(_:)`` function before they are submitted, and instances of ``AuthorizationProvider/AuthorizationRequest`` and assocated ``HTTPResponse`` from successful requests are passed to the ``AuthorizationProvider/handle(authorizationResponse:from:)`` function.
public struct AuthorizingHTTPController<Authorization: AuthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``HTTPSession`` used to fetch the raw `Data` ``HTTPResponse`` for a request.
    public let session: HTTPSession
        
    /// The ``AuthorizationProvider`` used to authorize requests that need it.
    public let authorization: Authorization
    
    /// The ``DataDecoder`` provided to a submitted ``HTTPRequest`` for decoding. It is best to set up a decoder suitable for the API once and reuse it. The ``HTTPRequest`` may still opt not to use this decoder.
    public let decoder: DataDecoder
    
    /// The type used to handle any errors that are thrown by the ``HTTPRequest/transform(data:statusCode:using:)`` function of a request. This is used to try and extract error messages from the response if possible. If this property is `nil` then the unaltered error is thrown.
    public let errorHandler: HTTPErrorHandler?

    /// The headers that will be applied to every request before submission.
    public let universalHeaders: [String : String]?
    
    // MARK: - Initialisers

    /// Creates a new ``AuthorizingHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``HTTPSession`` the controller will use.
    ///   - authorization: The ``AuthorizationProvider`` to use to authorize requests.
    ///   - decoder: The ``DataDecoder`` the controller will hand to requests for decoding.
    ///   - errorHandler: The ``HTTPErrorHandler`` that can be used to manipulate errors before they are thrown.
    ///   - universalHeaders: The headers applied to every request submitted.
    public init(
        baseURL: URL,
        session: HTTPSession = URLSession.shared,
        authorization: Authorization,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: HTTPErrorHandler? = nil,
        universalHeaders: [String : String]? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
        self.decoder = decoder
        self.errorHandler = errorHandler
        self.universalHeaders = universalHeaders
    }
}

// MARK: - HTTP controller
extension AuthorizingHTTPController: HTTPController {
    
    public func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.ResponseType> {
        
        let requestWithUniversalHeaders = add(
            universalHeaders: universalHeaders,
            to: request
        )
        let authorizedRequest = authorize(request: requestWithUniversalHeaders)
        
        let dataResponse = try await session.submit(
            request: authorizedRequest,
            to: baseURL
        )
        
        do {
            let response = try transform(
                dataResponse: dataResponse,
                from: request,
                using: decoder
            )
            
            extractAuthorizationContent(
                from: response,
                returnedBy: request
            )
            
            return response
            
        } catch {
            
            guard let errorHandler else {
                throw error
            }
            
            let mappedError = errorHandler.map(
                error,
                from: dataResponse
            )
            
            throw mappedError
        }
    }
}

// MARK: - Request modification
extension AuthorizingHTTPController {
    
    private func authorize<Request: HTTPRequest>(request: Request) -> any HTTPRequest<Request.ResponseType> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = authorization.authorize(request)
        
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
            let authorizationResponse = response as? HTTPResponse<Authorization.AuthorizationRequest.ResponseType>
        {
            authorization.handle(
                authorizationResponse: authorizationResponse,
                from: authorizationRequest
            )
        }
    }
}
