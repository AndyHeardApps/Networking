import Foundation
import Networking

final class MockNetworkErrorHandler {
    
    // MARK: - Properties
    private(set) var recievedError: Error?
    private(set) var recievedResponse: NetworkResponse<Data>?
    var result: Error!
}

// MARK: - Network error handler
extension MockNetworkErrorHandler: NetworkErrorHandler {
    
    func handle(_ error: Error, from response: NetworkResponse<Data>) -> Error {
        
        recievedError = error
        recievedResponse = response

        return result
    }
}
