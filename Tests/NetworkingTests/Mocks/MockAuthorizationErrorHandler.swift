import Foundation
import Networking

final class MockAuthorizationErrorHandler {
    
    // MARK: - Properties
    private(set) var recievedError: Error?
    private(set) var recievedResponse: NetworkResponse<Data>?
    var result: AuthorizationErrorHandlerResult = .attemptReauthorization
}

// MARK: - Authorization error handler
extension MockAuthorizationErrorHandler: AuthorizationErrorHandler {
    
    func handle(_ error: Error, from response: NetworkResponse<Data>) -> AuthorizationErrorHandlerResult {
        
        recievedError = error
        recievedResponse = response
        
        return result
    }
}
