import Foundation
@testable import Networking

final class MockAuthorizationProvider {
    
    // MARK: - Properties
    private(set) var handledAuthorizationResponse: NetworkResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockHTTPRequest<MockAccessToken>?
    private(set) var authorizedRequest: (any HTTPRequest)?
}

// MARK: - Authorization provider
extension MockAuthorizationProvider: AuthorizationProvider {
    
    func handle(
        authorizationResponse: NetworkResponse<MockAccessToken>,
        from request: MockHTTPRequest<MockAccessToken>
    ) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.ResponseType> {
        
        self.authorizedRequest = request
        
        var headers = request.headers ?? [:]
        headers["Authorization"] = "true"
    
        let authorizedRequest = MockHTTPRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body as? UUID,
            requiresAuthorization: request.requiresAuthorization,
            transformClosure: request.transform
        )
        
        return authorizedRequest
    }
}
