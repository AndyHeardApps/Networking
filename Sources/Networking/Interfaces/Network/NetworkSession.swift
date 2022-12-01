import Foundation

public protocol NetworkSession {
    
    // MARK: - Functions
    
    func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data>
}
