import Foundation
@testable import Networking

final class MockHTTPSession {
    
    // MARK: - Properties
    private(set) var receivedRequests: [(request: any HTTPRequest, baseURL: URL)] = []
    private var responses: [HashableRequest : HTTPResponse<Data>] = [:]
    var shouldThrowErrorOnSubmit = false
}

// MARK: - HTTP session
extension MockHTTPSession: HTTPSession {
    
    func submit(request: some HTTPRequest, to baseURL: URL) async throws -> HTTPResponse<Data> {
        
        receivedRequests.append((request, baseURL))
        
        if shouldThrowErrorOnSubmit {
            throw SampleError()
        }
                
        if request.requiresAuthorization {
            if request.headers?["Authorization"] == "true" {
                let hashableRequest = HashableRequest(request: request)
                return responses[hashableRequest]!
            } else {
                return HTTPResponse(
                    content: Data(),
                    statusCode: .unauthorized,
                    headers: [:]
                )
            }
        } else {
            let hashableRequest = HashableRequest(request: request)
            return responses[hashableRequest]!
        }
    }
}

// MARK: - Response setting
extension MockHTTPSession {
    
    func set(response: HTTPResponse<Data>, for request: some HTTPRequest) {
        
        let hashableRequest = HashableRequest(request: request)
        responses[hashableRequest] = response
    }
    
    func set(data: Data, for request: some HTTPRequest) {
        
        set(
            response: .init(
                content: data,
                statusCode: .ok,
                headers: [:]
            ),
            for: request
        )
    }
    
    func setBlankResponse(for request: some HTTPRequest) {
        
        set(
            data: .init(),
            for: request
        )
    }
    
    func setReauthorizationResponse() {
        
        let reauthorizationRequest = MockHTTPRequest(
            httpMethod: .get,
            pathComponents: ["mockReauthorization"],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: false
        ) { _, _, _ in }

        set(data: .init(), for: reauthorizationRequest)
    }
}

// MARK: - Hashable request
extension MockHTTPSession {
    
    private struct HashableRequest: Hashable {
        
        // Properties
        let httpMethod: HTTPMethod
        let pathComponents: [String]
        let queryItems: [String : String]?
        let body: Data?
        let requiresAuthorization: Bool
        
        // Initialiser
        init(request: some HTTPRequest) {
            
            self.httpMethod = request.httpMethod
            self.pathComponents = request.pathComponents
            self.queryItems = request.queryItems
            self.body = try? JSONEncoder().encode(request.body)
            self.requiresAuthorization = request.requiresAuthorization
        }
    }
}

// MARK: - Errors
extension MockHTTPSession {
    
    struct SampleError: Error {
        
        fileprivate init() {}
    }
}
