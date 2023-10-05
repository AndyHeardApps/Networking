import Foundation
import Networking

final class MockHTTPErrorHandler {
    
    // MARK: - Properties
    private(set) var recievedError: Error?
    private(set) var recievedResponse: HTTPResponse<Data>?
    var result: Error!
}

// MARK: - HTTP error handler
extension MockHTTPErrorHandler: HTTPErrorHandler {
    
    func map(
        _ error: Error,
        from response: HTTPResponse<Data>
    ) -> Error {
        
        recievedError = error
        recievedResponse = response

        return result
    }
}
