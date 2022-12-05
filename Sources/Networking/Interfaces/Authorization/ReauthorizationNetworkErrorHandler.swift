import Foundation

public protocol ReauthorizationNetworkErrorHandler: NetworkErrorHandler {
    
    func shouldAttemptReauthorization(afterCatching error: Error, from response: NetworkResponse<Data>) -> Bool
}
