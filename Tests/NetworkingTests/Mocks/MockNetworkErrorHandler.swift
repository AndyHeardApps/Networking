import Foundation
import Networking

final class MockNetworkErrorHandler {
    
    // MARK: - Properties
    private(set) var recievedError: Error?
    private(set) var recievedResponse: HTTPResponse<Data>?
    var result: Error!
}

// MARK: - Network error handler
extension MockNetworkErrorHandler: NetworkErrorHandler {
    
    func map(
        _ error: Error,
        from response: HTTPResponse<Data>
    ) -> Error {
        
        recievedError = error
        recievedResponse = response

        return result
    }
}
