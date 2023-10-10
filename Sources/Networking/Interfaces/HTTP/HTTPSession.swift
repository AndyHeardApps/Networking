import Foundation

/// Defines an interface for submitting a ``HTTPRequest`` with a ``HTTPRequest/Body`` type of `Data` against some `baseURL` and returning a ``HTTPResponse`` containing raw `Data`.
///
/// By default, `URLSession` implements this protocol, build a `URLRequest` out of the ``HTTPRequest``.
public protocol HTTPSession {
    
    // MARK: - Functions
    
    /// Submits a ``HTTPRequest`` against a  base `URL`.
    ///
    /// The `baseURL`, ``HTTPRequest/pathComponents``, and ``HTTPRequest/queryItems`` are combined to build the full `URL` before submission.
    /// - Parameters:
    ///   - request: The ``HTTPRequest`` to submit.
    ///   - baseURL: The base `URL` to submit the `request` against. This base `URL` will have the ``HTTPRequest/pathComponents`` and ``HTTPRequest/queryItems`` appended to build the full URL.
    /// - Returns: The ``HTTPResponse`` for the `request` containing raw `Data`.
    /// - Throws: Any network errors that occurred when fetching the request.
    func submit<Request>(
        request: Request,
        to baseURL: URL
    ) async throws -> HTTPResponse<Data> 
    where Request: HTTPRequest,
          Request.Body == Data
}
