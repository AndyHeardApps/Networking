import Foundation

public protocol NetworkController {
    
    // MARK: - Functions
        
    func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType>
}

extension NetworkController {
    
    public func fetchContent<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        try await fetchResponse(request).content
    }
}
