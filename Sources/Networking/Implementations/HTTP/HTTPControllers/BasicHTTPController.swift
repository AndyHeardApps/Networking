import Foundation

/// A basic implementation of a ``HTTPController``, with no authorization on requests. This type will submit requests using the provided ``HTTPSession`` and transform responses using the ``HTTPRequest/transform(data:statusCode:using:)`` function.
///
/// Any request errors are handed to the ``errorHandler`` to enable more information to be extracted where possible before throwing the error.
///
/// The ``universalHeaders`` property can be used to add a static set of headers to every request submitted, such as API keys.
///
/// Though the implementation is intentionally lightweight, it is best if an instance is created once for each `baseURL` on app launch, and held for reuse.
public struct BasicHTTPController {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``HTTPSession`` used to fetch the raw `Data` ``HTTPResponse`` for a request.
    public let session: HTTPSession
    
    /// The ``DataDecoder`` provided to a submitted ``HTTPRequest`` for decoding. It is best to set up a decoder suitable for the API once and reuse it. The ``HTTPRequest`` may still opt not to use this decoder.
    public let decoder: DataDecoder
        
    /// The type used to handle any errors that are thrown by the ``HTTPRequest/transform(data:statusCode:using:)`` function of a request. This is used to try and extract error messages from the response if possible. If this property is `nil` then the unaltered error is thrown.
    public let errorHandler: HTTPErrorHandler?

    /// The headers that will be applied to every request before submission.
    public let universalHeaders: [String : String]?

    // MARK: - Initialisers
    
    /// Creates a new ``BasicHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``HTTPSession`` the controller will use.
    ///   - decoder: The ``DataDecoder`` the controller will hand to requests for decoding.
    ///   - errorHandler: The ``HTTPErrorHandler`` that can be used to manipulate errors before they are thrown.
    ///   - universalHeaders: The headers applied to every request submitted.
    public init(
        baseURL: URL,
        session: HTTPSession = URLSession.shared,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: HTTPErrorHandler? = nil,
        universalHeaders: [String : String]? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.errorHandler = errorHandler
        self.universalHeaders = universalHeaders
    }
}

// MARK: - HTTP controller
extension BasicHTTPController: HTTPController {
    
    public func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.ResponseType> {

        if request.requiresAuthorization {
            throw HTTPStatusCode.unauthorized
        }
        
        let requestWithUniversalHeaders = add(
            universalHeaders: universalHeaders,
            to: request
        )
        
        let dataResponse = try await session.submit(
            request: requestWithUniversalHeaders,
            to: baseURL
        )
        
        do {
            let response = try transform(
                dataResponse: dataResponse,
                from: request,
                using: decoder
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
