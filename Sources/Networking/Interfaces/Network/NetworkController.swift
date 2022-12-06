import Foundation

/// Defines an entrypoint for fetching content from a ``NetworkRequest``.
///
/// There are three default types that implement this protocol, ``BasicNetworkController``, ``AuthorizingNetworkController``, and ``ReauthorizingNetworkController``. These can be used depending on how much security an API requires.
public protocol NetworkController {
    
    // MARK: - Functions
    
    /// Fetches the response for a given ``NetworkRequest``.
    /// - Parameter request: The ``NetworkRequest`` to be submitted.
    /// - Returns: The ``NetworkResponse`` returned by the `request`.
    /// - Throws: Any errors that occurred when fetching the response. Usually this is a network or decoding error. See ``HTTPStatusCode``.
    func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType>
}

// MARK: - Convenienc method
extension NetworkController {
    
    /// Fetches the response contents for a given ``NetworkRequest``. This is a convenience method fo when the ``NetworkResponse/headers`` and ``NetworkResponse/statusCode``of a ``NetworkResponse`` are not needed.
    /// - Parameter request: The ``NetworkRequest`` to be submitted.
    /// - Returns: The ``NetworkResponse/content`` returned by the `request`.
    /// - Throws: Any errors that occurred when fetching the response. Usually this is a network or decoding error. See ``HTTPStatusCode``.
    public func fetchContent<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        try await fetchResponse(request).content
    }
}
