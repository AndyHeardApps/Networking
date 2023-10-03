import Foundation
@testable import Networking

final class MockAuthorizationProvider {
    
    // MARK: - Properties
    private(set) var handledAuthorizationResponse: NetworkResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockNetworkRequest<MockAccessToken>?
    private(set) var authorizedRequest: (any NetworkRequest)?
}

// MARK: - Authorization provider
extension MockAuthorizationProvider: AuthorizationProvider {
    
    func handle(
        authorizationResponse: NetworkResponse<MockAccessToken>,
        from request: MockNetworkRequest<MockAccessToken>
    ) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        self.authorizedRequest = request
        
        var headers = request.headers ?? [:]
        headers["Authorization"] = "true"
    
        let authorizedRequest = MockNetworkRequest(
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
