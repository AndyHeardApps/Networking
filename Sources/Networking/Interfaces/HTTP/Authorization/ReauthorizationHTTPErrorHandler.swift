import Foundation

/// Describes a type that handles errors produced by a ``ReauthorizingHTTPController``.
///
/// This protocol extends the functionality required by a ``HTTPErrorHandler`` to decide whether reauthentication should be attempted by a ``ReauthorizingHTTPController`` using its ``HTTPReauthorizationProvider``.
///
/// For discussion on the ``HTTPErrorHandler/map(_:from:)`` function required by this type, refer to the ``HTTPErrorHandler`` documentation.
///
/// A ``HTTPReauthorizationProvider`` needs to know when a thrown error is recoverable by reauthorizing and retrying the request. That decision is usually specific to the API being used and the error types it provides. The ``shouldAttemptReauthorization(afterCatching:from:)`` function is called by a ``ReauthorizingHTTPController``, and should examine the provided error and response ``HTTPResponse/content`` to see if the error is one that can be recovered by reauthorizing.
public protocol ReauthorizationHTTPErrorHandler: HTTPErrorHandler {
    
    
    /// Decides whether or not the provided `error` is recoverable by reauthorizing and retrying a request. The `response` provided is the ``HTTPResponse`` returned by the failed request that contains the raw `Data` for the response.
    /// - Parameters:
    ///   - error: The error thrown by a request.
    ///   - response: The response containing raw data that caused the request to throw an error.
    /// - Returns: Whether or not a ``ReauthorizingHTTPController`` should attempt reauthorization and resubmission of the failed request.
    func shouldAttemptReauthorization(
        afterCatching error: Error,
        from response: HTTPResponse<Data>
    ) -> Bool
}