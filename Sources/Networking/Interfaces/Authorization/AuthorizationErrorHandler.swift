import Foundation

/// A type that decides how an error thrown by an `AuthorizingNetworkController` is handled.
public protocol AuthorizationErrorHandler {
    
    // MARK: - Functions
    
    /// Handles the provided error thrown by a `NetworkRequest`, the provided error and `NetworkResponse<Data>` can be used to decide whether to attempt reathorization, and reattempt of the request, or to throw an error. The contents of the response can be used to decode custom errors.
    /// - Parameters:
    ///   - error: The error thrown by the `AuthorizingNetworkController`.
    ///   - response: The response of the request that caused the error to be thrown.
    /// - Returns: A decision to either attempt reauthorization, or to throw an error.
    func handle(_ error: Error, from response: NetworkResponse<Data>) -> AuthorizationErrorHandlerResult
}
