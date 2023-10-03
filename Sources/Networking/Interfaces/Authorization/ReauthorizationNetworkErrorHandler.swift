import Foundation

/// Describes a type that handles errors produced by a ``ReauthorizingNetworkController``.
///
/// This protocol extends the functionality required by a ``NetworkErrorHandler`` to decide whether reauthentication should be attempted by a ``ReauthorizingNetworkController`` using its ``ReauthorizationProvider``.
///
/// For discussion on the ``NetworkErrorHandler/map(_:from:)`` function required by this type, refer to the ``NetworkErrorHandler`` documentation.
///
/// A ``ReauthorizationProvider`` needs to know when a thrown error is recoverable by reauthorizing and retrying the request. That decision is usually specific to the API being used and the error types it provides. The ``shouldAttemptReauthorization(afterCatching:from:)`` function is called by a ``ReauthorizingNetworkController``, and should examine the provided error and response ``NetworkResponse/content`` to see if the error is one that can be recovered by reauthorizing.
public protocol ReauthorizationNetworkErrorHandler: NetworkErrorHandler {
    
    
    /// Decides whether or not the provided `error` is recoverable by reauthorizing and retrying a request. The `response` provided is the ``NetworkResponse`` returned by the failed request that contains the raw `Data` for the response.
    /// - Parameters:
    ///   - error: The error thrown by a request.
    ///   - response: The response containing raw data that caused the request to throw an error.
    /// - Returns: Whether or not a ``ReauthorizingNetworkController`` should attempt reauthorization and resubmission of the failed request.
    func shouldAttemptReauthorization(
        afterCatching error: Error,
        from response: NetworkResponse<Data>
    ) -> Bool
}
