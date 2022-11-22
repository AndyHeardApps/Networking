import Foundation

/// The decision returned by an `AuthorizationErrorHandler`, either attempting to reauthorize and resubmit the request that resulted in an error, or return an error.
public enum AuthorizationErrorHandlerResult {
    
    // MARK: - Cases
    
    /// Returning this in an `AuthorizationErrorHandler` `handle` function will cause the `AuthorizingNetworkController` to attempt to reauthorize and resubmit the request that resulted in an error using its `AuthorizationProvider`.
    case attemptReauthorization
    
    /// Returning this will result in the provided error being thrown by the `AuthorizingNetworkController`. A custor error can be decoded in the `AuthorizationErrorHandler` `handle` function and thrown if necessary.
    case error(Error)
}
