import Foundation

/// The default `AuthorizationErrorHandler` that will try to reauthorize when a `HTTPStatusCode.unauthorized` error is recieved, otherwise, the error is thrown unmodified.
public struct DefaultAuthorizationErrorHandler {
    
    // MARK: - Initialiser
    public init() {}
}

// MARK: - Authorization error handler
extension DefaultAuthorizationErrorHandler: AuthorizationErrorHandler {
    
    public func handle(_ error: Error, from response: NetworkResponse<Data>) -> AuthorizationErrorHandlerResult {
        
        switch error {
        case HTTPStatusCode.unauthorized:
            return .attemptReauthorization
            
        default:
            return .error(error)
        }
    }
}
