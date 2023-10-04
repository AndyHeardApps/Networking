import Foundation
@testable import Networking

final class MockReauthorizationProvider {
    
    // MARK: - Properties
    var shouldMakeReauthorizationRequest = true
    var authorizationFailsUntilReauthorizationRequestIsMade = false
    private var hasCreatedReauthorizationRequest = false
    private(set) var makeReauthorizationRequestWasCalled = false
    private(set) var handledAuthorizationResponse: HTTPResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockHTTPRequest<MockAccessToken>?
    private(set) var handledReauthorizationResponse: HTTPResponse<MockRefreshToken>?
    private(set) var handledReauthorizationResponseRequest: MockHTTPRequest<MockRefreshToken>?
    private(set) var authorizedRequest: (any HTTPRequest)?
}

// MARK: - Reauthorization provider
extension MockReauthorizationProvider: ReauthorizationProvider {
    
    func makeReauthorizationRequest() -> MockHTTPRequest<MockRefreshToken>? {
        
        makeReauthorizationRequestWasCalled = true
        
        guard shouldMakeReauthorizationRequest else {
            return nil
        }
        
        hasCreatedReauthorizationRequest = true
        return MockHTTPRequest(
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
    
    func handle(
        authorizationResponse: HTTPResponse<MockAccessToken>,
        from request: MockHTTPRequest<MockAccessToken>
    ) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func handle(
        reauthorizationResponse: HTTPResponse<MockRefreshToken>,
        from request: MockHTTPRequest<MockRefreshToken>
    ) {
        
        self.handledReauthorizationResponse = reauthorizationResponse
        self.handledReauthorizationResponseRequest = request
    }
    
    func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.ResponseType> {
        
        self.authorizedRequest = request
        
        var headers = request.headers ?? [:]
        
        if authorizationFailsUntilReauthorizationRequestIsMade, !hasCreatedReauthorizationRequest {
            headers["Authorization"] = "false"
        } else {
            headers["Authorization"] = "true"
        }
    
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
