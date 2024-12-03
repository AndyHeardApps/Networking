import Foundation
@testable import Networking

final class MockHTTPAuthorizationProvider: @unchecked Sendable {
    
    // MARK: - Properties
    private(set) var handledAuthorizationResponse: HTTPResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockHTTPRequest<Data, MockAccessToken>?
    private(set) var authorizedRequest: (any HTTPRequest)?
}

// MARK: - HTTP Authorization provider
extension MockHTTPAuthorizationProvider: HTTPAuthorizationProvider {
    
    func handle(
        authorizationResponse: HTTPResponse<MockAccessToken>,
        from request: MockHTTPRequest<Data, MockAccessToken>
    ) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.Body, Request.Response> {
        
        self.authorizedRequest = request
        
        var headers = request.headers ?? [:]
        headers["Authorization"] = "true"
    
        let authorizedRequest = MockHTTPRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            encode: request.encode,
            decode: request.decode
        )
        
        return authorizedRequest
    }
}
