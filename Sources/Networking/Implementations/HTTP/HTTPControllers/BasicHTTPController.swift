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
    
    public let dataCoders: DataCoders
    
    public let delegate: HTTPControllerDelegate

    // MARK: - Initialisers
    
    /// Creates a new ``BasicHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``HTTPSession`` the controller will use.
    ///   - errorHandler: The ``HTTPErrorHandler`` that can be used to manipulate errors before they are thrown.
    public init(
        baseURL: URL,
        session: HTTPSession = URLSession.shared,
        dataCoders: DataCoders,
        delegate: HTTPControllerDelegate? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.dataCoders = dataCoders
        self.delegate = delegate ?? DefaultHTTPControllerDelegate()
    }
}

// MARK: - HTTP controller
extension BasicHTTPController: HTTPController {
    
    public func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.Response> {

        if request.requiresAuthorization {
            throw HTTPStatusCode.unauthorized
        }
        
        let rawDataRequest = try delegate.controller(
            self,
            prepareRequestForSubmission: request,
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
