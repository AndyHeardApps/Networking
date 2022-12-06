import Foundation

/// Defines an interface for submitting a ``NetworkRequest`` against some `baseURL` and returning a ``NetworkResponse`` containing raw `Data`.
///
/// By default, `URLSession` implements this protocol, build a `URLRequest` out of the ``NetworkRequest``.
public protocol NetworkSession {
    
    // MARK: - Functions
    
    /// Submits a ``NetworkRequest`` against a  base `URL`.
    ///
    /// The `baseURL`, ``NetworkRequest/pathComponents``, and ``NetworkRequest/queryItems`` are combined to build the full `URL` before submission.
    /// - Parameters:
    ///   - request: The ``NetworkRequest`` to submit.
    ///   - baseURL: The base `URL` to submit the `request` against. This base `URL` will have the ``NetworkRequest/pathComponents`` and ``NetworkRequest/queryItems`` appended to build the full URL.
    /// - Returns: The ``NetworkResponse`` for the `request` containing raw `Data`.
    /// - Throws: Any network errors that occurred when fetching the request.
    func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data>
}
