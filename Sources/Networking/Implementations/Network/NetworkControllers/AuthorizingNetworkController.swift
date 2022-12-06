import Foundation

/// A ``NetworkController`` that authorizes every request submitted using the provided ``AuthorizationProvider``.
///
/// This type extends the basic implementation of the ``BasicNetworkController``, so refer to its documentation for basic usage.
///
/// This difference between ``BasicNetworkController`` and ``AuthorizingNetworkController`` is that every request submitted through this type with ``NetworkRequest/requiresAuthorization`` equal to `true` will try and have authorizing credentials attached using the provided ``AuthorizationProvider`` before it is submitted.
///
/// Requests are handed to the ``AuthorizationProvider/authorize(_:)`` function before they are submitted, and instances of ``AuthorizationProvider/AuthorizationRequest`` and assocated ``NetworkResponse`` from successful requests are passed to the ``AuthorizationProvider/handle(authorizationResponse:from:)`` function.
public struct AuthorizingNetworkController<Authorization: AuthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``NetworkRequest/pathComponents`` and ``NetworkRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``NetworkSession`` used to fetch the raw `Data` ``NetworkResponse`` for a request.
    public let session: NetworkSession
        
    /// The ``AuthorizationProvider`` used to authorize requests that need it.
    public let authorization: Authorization
    
    /// The ``DataDecoder`` provided to a submitted ``NetworkRequest`` for decoding. It is best to set up a decoder suitable for the API once and reuse it. The ``NetworkRequest`` may still opt not to use this decoder.
    public let decoder: DataDecoder
    
    /// The type used to handle any errors that are thrown by the ``NetworkRequest/transform(data:statusCode:using:)`` function of a request. This is used to try and extract error messages from the response if possible. If this property is `nil` then the unaltered error is thrown.
    public let errorHandler: NetworkErrorHandler?

    /// The headers that will be applied to every request before submission.
    public let universalHeaders: [String : String]?
    
    // MARK: - Initialisers

    /// Creates a new ``AuthorizingNetworkController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``NetworkSession`` the controller will use.
    ///   - authorization: The ``AuthorizationProvider`` to use to authorize requests.
    ///   - decoder: The ``DataDecoder`` the controller will hand to requests for decoding.
    ///   - errorHandler: The ``NetworkErrorHandler`` that can be used to manipulate errors before they are thrown.
    ///   - universalHeaders: The headers applied to every request submitted.
    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: NetworkErrorHandler? = nil,
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

// MARK: - Network controller
extension AuthorizingNetworkController: NetworkController {
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
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
extension AuthorizingNetworkController {
    
    private func authorize<Request: NetworkRequest>(request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = authorization.authorize(request)
        
        return authorizedRequest
    }
}
    
// MARK: - Authorized content extraction
extension AuthorizingNetworkController {
    
    private func extractAuthorizationContent<Response>(
        from response: NetworkResponse<Response>,
        returnedBy request: some NetworkRequest
    ) {
        
        if
            let authorizationRequest = request as? Authorization.AuthorizationRequest,
            let authorizionResponse = response as? NetworkResponse<Authorization.AuthorizationRequest.ResponseType>
        {
            authorization.handle(
                authorizationResponse: authorizionResponse,
                from: authorizationRequest
            )
        }
    }
}
