import Foundation

/// A ``NetworkController`` that authorizes every request submitted using the provided ``ReauthorizationProvider``, and attempts to reauthorize the app whenever authorization fails.
///
/// This type extends the authorizing behavior of the ``AuthorizingNetworkController``, so refer to its documentation for authorization details.
///
/// This difference between ``AuthorizingNetworkController`` and ``ReauthorizingNetworkController`` is that the ``errorHandler`` is a ``ReauthorizationNetworkErrorHandler`` that has the additional ``ReauthorizationNetworkErrorHandler/shouldAttemptReauthorization(afterCatching:from:)`` function that decides whether a thrown error can be recovered by reauthorizing and resubmitting the request. In addition, the ``authorization`` is a ``ReauthorizationProvider``, that provides the ``ReauthorizationProvider/makeReauthorizationRequest()`` and ``ReauthorizationProvider/handle(reauthorizationResponse:from:)`` functions for creating reauthorizing requests and handling their responses.
///
/// As with the ``AuthorizingNetworkController``, requests are handed to the ``AuthorizationProvider/authorize(_:)`` function before they are submitted, and instances of ``AuthorizationProvider/AuthorizationRequest`` and assocated ``NetworkResponse`` from successful requests are passed to the ``AuthorizationProvider/handle(authorizationResponse:from:)`` function.
///
/// If the requests ``NetworkRequest/transform(data:statusCode:using:)`` function throws an error and the ``errorHandler`` is not `nil`, it is passed to the ``ReauthorizationNetworkErrorHandler/shouldAttemptReauthorization(afterCatching:from:)`` function. If it returns `true` then the ``ReauthorizationProvider/makeReauthorizationRequest()`` function is used to create and submit a reauthorizing request. The initial failed request then has the updated credentials added to it and is resubmitted. If the ``errorHandler`` is nil, then this same logic is applied for a ``HTTPStatusCode/unauthorized`` status code by default.
public struct ReauthorizingNetworkController<Authorization: ReauthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``NetworkRequest/pathComponents`` and ``NetworkRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``NetworkSession`` used to fetch the raw `Data` ``NetworkResponse`` for a request.
    public let session: NetworkSession
    
    /// The ``ReauthorizationProvider`` used to authorize requests that need it, and reauthorize the app whenever possible.
    public let authorization: Authorization
    
    /// The ``DataDecoder`` provided to a submitted ``NetworkRequest`` for decoding. It is best to set up a decoder suitable for the API once and reuse it. The ``NetworkRequest`` may still opt not to use this decoder.
    public let decoder: DataDecoder
    
    /// The type used to handle any errors that are thrown by the ``NetworkRequest/transform(data:statusCode:using:)`` function of a request. This is used to decide whether or not to try and reauthorize the app. If not, then it will try and extract error messages from the response if possible. If this property is `nil` then the reauthorizing flow is triggered for a ``HTTPStatusCode/unauthorized`` status code, and unaltered errors are thrown if it fails.
    public let errorHandler: ReauthorizationNetworkErrorHandler?
    
    /// The headers that will be applied to every request before submission.
    public let universalHeaders: [String : String]?
    
    // MARK: - Initialisers

    /// Creates a new ``ReauthorizingNetworkController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``NetworkSession`` the controller will use.
    ///   - authorization: The ``ReauthorizationProvider`` to use to authorize requests.
    ///   - decoder: The ``DataDecoder`` the controller will hand to requests for decoding.
    ///   - errorHandler: The ``ReauthorizationNetworkErrorHandler`` that can be used to manipulate errors before they are thrown, and decide whether reauthorization should be attempted.
    ///   - universalHeaders: The headers applied to every request submitted.
    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        authorization: Authorization,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: ReauthorizationNetworkErrorHandler? = nil,
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
extension ReauthorizingNetworkController: NetworkController {
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        try await fetchResponse(request, shouldAttemptReauthorization: true)
    }
    
    public func fetchResponse<Request: NetworkRequest>(
        _ request: Request,
        shouldAttemptReauthorization: Bool
    ) async throws -> NetworkResponse<Request.ResponseType> {
        
        let requestWithUniversalHeaders = add(universalHeaders: universalHeaders, to: request)
        let authorizedRequest = authorize(request: requestWithUniversalHeaders)
        
        // Errors thrown here cannot be fixed with reauth
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
            
            let errorHandlingResult = handle(
                error,
                from: dataResponse,
                shouldAttemptReauthorization: shouldAttemptReauthorization
            )
            switch errorHandlingResult {
            case .attemptReauthorization:
                break
                
            case .error(let error):
                throw error
                
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
extension ReauthorizingNetworkController {
    
    private func authorize<Request: NetworkRequest>(request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        guard request.requiresAuthorization else {
            return request
        }
        
        let authorizedRequest = authorization.authorize(request)
        
        return authorizedRequest
    }
}

// MARK: - Error handling
extension ReauthorizingNetworkController {

    private enum ErrorHandlingResult {
        
        case attemptReauthorization
        case error(Error)
    }
    
    private func handle(
        _ error: Error,
        from response: NetworkResponse<Data>,
        shouldAttemptReauthorization: Bool
    ) -> ErrorHandlingResult {
        
        switch (shouldAttemptReauthorization, errorHandler) {
        case (true, let errorHandler?):
            guard errorHandler.shouldAttemptReauthorization(afterCatching: error, from: response) else {
                let mappedError = errorHandler.map(error, from: response)
                return .error(mappedError)
            }
            return .attemptReauthorization

        case (false, let errorHandler?):
            let mappedError = errorHandler.map(error, from: response)
            return .error(mappedError)

        case (true, nil) where error as? HTTPStatusCode == .unauthorized:
            return .attemptReauthorization
            
        case (_, nil):
            return .error(error)

        }
    }
}

// MARK: - Reauthorization
extension ReauthorizingNetworkController {
    
    private func reauthorize(
        afterError originalError: Error,
        from originalResponse: NetworkResponse<Data>
    ) async throws {
        
        do {
            guard
                let reauthorizationRequest = authorization.makeReauthorizationRequest(),
                !reauthorizationRequest.requiresAuthorization
            else {
                throw originalError
            }
            
            let requestWithUniversalHeaders = add(universalHeaders: universalHeaders, to: reauthorizationRequest)
            
            let dataResponse = try await session.submit(
                request: requestWithUniversalHeaders,
                to: baseURL
            )
            
            let reauthorizationResponse = try transform(
                dataResponse: dataResponse,
                from: reauthorizationRequest,
                using: decoder
            )
            
            extractAuthorizationContent(
                from: reauthorizationResponse,
                returnedBy: reauthorizationRequest
            )
        } catch {
            guard let errorHandler else {
                throw originalError
            }
            
            let mappedError = errorHandler.map(originalError, from: originalResponse)
            throw mappedError
        }
    }
}

// MARK: - Authorized content extraction
extension ReauthorizingNetworkController {
    
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
        
        if
            let reauthorizationRequest = request as? Authorization.ReauthorizationRequest,
            let reauthorizionResponse = response as? NetworkResponse<Authorization.ReauthorizationRequest.ResponseType>
        {
            authorization.handle(
                reauthorizationResponse: reauthorizionResponse,
                from: reauthorizationRequest
            )
        }
    }
}
