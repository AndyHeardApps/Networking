import Foundation

/// Defines an entrypoint for fetching content from a ``HTTPRequest``.
///
/// There are three default types that implement this protocol, ``BasicHTTPController``, ``AuthorizingHTTPController``, and ``ReauthorizingHTTPController``. These can be used depending on how much security an API requires.
public protocol HTTPController {
    
    // MARK: - Functions
    
    /// Fetches the response for a given ``HTTPRequest``.
    /// - Parameter request: The ``HTTPRequest`` to be submitted.
    /// - Returns: The ``HTTPResponse`` returned by the `request`.
    /// - Throws: Any errors that occurred when fetching the response. Usually this is a network or decoding error. See ``HTTPStatusCode``.
    func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.ResponseType>
}

// MARK: - Convenience method
extension HTTPController {
    
    /// Fetches the response contents for a given ``HTTPRequest``. This is a convenience method fo when the ``HTTPResponse/headers`` and ``HTTPResponse/statusCode`` of a ``HTTPResponse`` are not needed.
    /// - Parameter request: The ``HTTPRequest`` to be submitted.
    /// - Returns: The ``HTTPResponse/content`` returned by the `request`.
    /// - Throws: Any errors that occurred when fetching the response. Usually this is a network or decoding error. See ``HTTPStatusCode``.
    public func fetchContent<Request: HTTPRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        try await fetchResponse(request).content
    }
}
