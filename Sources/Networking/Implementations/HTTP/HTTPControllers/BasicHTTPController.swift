import Foundation

/// A basic implementation of a ``HTTPController``, with no authorization on requests. This type will submit requests using the provided ``HTTPSession``, encoding the ``HTTPRequest/body-6nbh7`` of the reqest using ``HTTPRequest/encode(body:headers:using:)-7qe3v`` and decoding the response using ``HTTPRequest/decode(data:statusCode:using:)``.
///
/// For further control over preparing the requests for submission or handling responses and errors, create a custom ``HTTPControllerDelegate`` and provide it in the initialiser. This allows you to decode API errors, add headers to every request or encrypt and decrypt content.
///
/// Though the implementation is intentionally lightweight, it is best if an instance is created once for each `baseURL` on app launch, and held for reuse.
public struct BasicHTTPController {
    
    // MARK: - Properties
    
    /// The base `URL` to submit all requests to. This is the base `URL` used to construct the full `URL` using the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``HTTPSession`` used to fetch the raw `Data` ``HTTPResponse`` for a request.
    public let session: HTTPSession
    
    /// A collection of ``DataEncoder`` and ``DataDecoder`` objects that the controller will use to encode and decode specific HTTP content types.
    public let dataCoders: DataCoders
    
    /// The delegate used to provide additional control over preparing a request to be sent, handling responses, and handling errors.
    public let delegate: HTTPControllerDelegate

    // MARK: - Initialiser
    
    #if os(iOS) || os(macOS)
    /// Creates a new ``BasicHTTPController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``HTTPSession`` the controller will use to submit requests.
    ///   - dataCoders: The ``DataCoders`` that can be used to encode and decode request body and responses. By default, only JSON coders will be available.
    ///   - delegate: The ``HTTPControllerDelegate`` for the controller to use. If none is provided, then a default implementation is used to provide standard functionality.
    public init(
        baseURL: URL,
        session: HTTPSession = URLSession.shared,
        dataCoders: DataCoders = .default,
        delegate: HTTPControllerDelegate? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.dataCoders = dataCoders
        self.delegate = delegate ?? DefaultHTTPControllerDelegate()
    }
    #endif
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
                from: dataResponse,
                using: dataCoders
            )
            
            throw mappedError
        }
    }
}
