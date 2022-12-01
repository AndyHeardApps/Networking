import Foundation
import Networking

final class MockReauthorizationNetworkErrorHandler {

    // MARK: - Properties
    private(set) var recievedError: Error?
    private(set) var recievedResponse: NetworkResponse<Data>?
    var result: ReauthorizationErrorHandlerResult = .attemptReauthorization
}

// MARK: - Network error handler
extension MockReauthorizationNetworkErrorHandler: NetworkErrorHandler {

    func handle(_ error: Error, from response: NetworkResponse<Data>) -> ReauthorizationErrorHandlerResult {

        recievedError = error
        recievedResponse = response

        return result
    }
}
