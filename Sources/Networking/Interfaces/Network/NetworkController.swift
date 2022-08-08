import Foundation

/// A type that fetches and transforms the contents of a `NetworkRequest`.
public protocol NetworkController {
    
    // MARK: - Functions
    
    /// Submits a `request` and returns only the transformed content of the `request`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: The transformed content of the `request`s endpoint.
    func fetchContent<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType
    
    /// Submits a `request` and returns the transformed contents of the `request` alongside the `HTTPStatusCode` and `headers`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: A `NetworkResponse` containing transformed content of the `request`s endpoint, as well as the `HTTPStatusCode` and `headers` returned.
    func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType>
}
