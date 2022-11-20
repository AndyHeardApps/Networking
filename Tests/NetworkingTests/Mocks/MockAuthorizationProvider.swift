import Foundation
@testable import Networking

final class MockAuthorizationProvider {
    
    // MARK: - Properties
    var shouldMakeReauthorizationRequest = true
    var authorizationFailsUntilReauthorizationRequestIsMade = false
    private var hasCreatedReauthorizationRequest = false
    private(set) var makeReauthorizationRequestWasCalled = false
    private(set) var handledAuthorizationResponse: NetworkResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockNetworkRequest<MockAccessToken>?
    private(set) var handledReauthorizationResponse: NetworkResponse<MockRefreshToken>?
    private(set) var handledReauthorizationResponseRequest: MockNetworkRequest<MockRefreshToken>?
    private(set) var authorizedRequest: (any NetworkRequest)?
}

// MARK: - Authorization provider
extension MockAuthorizationProvider: AuthorizationProvider {
    
    func makeReauthorizationRequest() -> MockNetworkRequest<MockRefreshToken>? {
        
        makeReauthorizationRequestWasCalled = true
        
        guard shouldMakeReauthorizationRequest else {
            return nil
        }
        
        hasCreatedReauthorizationRequest = true
        return MockNetworkRequest(
            httpMethod: .get,
            pathComponents: ["mockReauthorization"],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: false
        ) { _, _, _ in
            .init(value: "mockToken")
        }
    }
    
    func handle(authorizationResponse: NetworkResponse<MockAccessToken>, from request: MockNetworkRequest<MockAccessToken>) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func handle(reauthorizationResponse: NetworkResponse<MockRefreshToken>, from request: MockNetworkRequest<MockRefreshToken>) {
        
        self.handledReauthorizationResponse = reauthorizationResponse
        self.handledReauthorizationResponseRequest = request
    }
    
    func authorize<Request: NetworkRequest>(_ request: Request) -> any NetworkRequest<Request.ResponseType> {
        
        self.authorizedRequest = request
        
        var headers = request.headers ?? [:]
        
        if authorizationFailsUntilReauthorizationRequestIsMade, !hasCreatedReauthorizationRequest {
            headers["Authorization"] = "false"
        } else {
            headers["Authorization"] = "true"
        }
    
        let authorizedRequest = MockNetworkRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            transformClosure: request.transform
        )
        
        return authorizedRequest
    }
}
