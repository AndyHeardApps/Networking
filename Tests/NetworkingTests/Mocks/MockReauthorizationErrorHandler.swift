import Foundation
import Networking

final class MockReauthorizationNetworkErrorHandler {

    // MARK: - Properties
    private(set) var recievedMappingError: Error?
    private(set) var recievedMappingResponse: HTTPResponse<Data>?
    var mapResult: Error!
    
    private(set) var recievedAttemptReauthorizationError: Error?
    private(set) var recievedAttemptReauthorizationResponse: HTTPResponse<Data>?
    var shouldAttemptReauthorizationResult = true
}

// MARK: - Network error handler
extension MockReauthorizationNetworkErrorHandler: ReauthorizationNetworkErrorHandler {

    func map(
        _ error: Error,
        from response: HTTPResponse<Data>
    ) -> Error {

        recievedMappingError = error
        recievedMappingResponse = response

        return mapResult
    }
    
    func shouldAttemptReauthorization(
        afterCatching error: Error,
        from response: HTTPResponse<Data>
    ) -> Bool {
        
        recievedAttemptReauthorizationError = error
        recievedAttemptReauthorizationResponse = response
        
        return shouldAttemptReauthorizationResult
    }
}
