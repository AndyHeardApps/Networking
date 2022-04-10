import Foundation

/// An abstraction of a network session that accepts a `NetworkRequest` and a base `URL` to resolve it against, and returns a `NetworkResponse` containing raw `Data`.
public protocol NetworkSession {
    
    // MARK: - Functions
    
    /// Submits a request and returns a `NetworkResponse` containing raw `Data`.
    /// - Parameters:
    ///     - request: The `NetworkRequest` being submitted.
    ///     - baseURL: The base URL to used with the `request` to construct a full URL.
    /// - Returns: A `NetworkResponse` containing the raw `Data` fetched from the URL resolved by the `request` and `baseURL`.
    func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data>
}
