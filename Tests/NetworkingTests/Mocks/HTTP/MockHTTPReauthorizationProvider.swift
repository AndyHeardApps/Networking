import Foundation
@testable import Networking

final class MockHTTPReauthorizationProvider {
    
    // MARK: - Properties
    var shouldMakeReauthorizationRequest = true
    var authorizationFailsUntilReauthorizationRequestIsMade = false
    private var hasCreatedReauthorizationRequest = false
    private(set) var makeReauthorizationRequestWasCalled = false
    private(set) var handledAuthorizationResponse: HTTPResponse<MockAccessToken>?
    private(set) var handledAuthorizationResponseRequest: MockHTTPRequest<Data, MockAccessToken>?
    private(set) var handledReauthorizationResponse: HTTPResponse<MockRefreshToken>?
    private(set) var handledReauthorizationResponseRequest: MockHTTPRequest<Data, MockRefreshToken>?
    private(set) var authorizedRequest: (any HTTPRequest)?
}

// MARK: - HTTP Reauthorization provider
extension MockHTTPReauthorizationProvider: HTTPReauthorizationProvider {
    
    func makeReauthorizationRequest() -> MockHTTPRequest<Data, MockRefreshToken>? {
        
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
            body: Data(),
            requiresAuthorization: false,
            encode: { body, _, _ in
                body
            },
            decode: { _, _, _ in
                .init(value: "mockToken")
            }
        )
    }
    
    func handle(
        authorizationResponse: HTTPResponse<MockAccessToken>,
        from request: MockHTTPRequest<Data, MockAccessToken>
    ) {
        
        self.handledAuthorizationResponse = authorizationResponse
        self.handledAuthorizationResponseRequest = request
    }
    
    func handle(
        reauthorizationResponse: HTTPResponse<MockRefreshToken>,
        from request: MockHTTPRequest<Data, MockRefreshToken>
    ) {
        
        self.handledReauthorizationResponse = reauthorizationResponse
        self.handledReauthorizationResponseRequest = request
    }
    
    func authorize<Request: HTTPRequest>(_ request: Request) -> any HTTPRequest<Request.Body, Request.Response> {
        
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
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            encode: request.encode,
            decode: request.decode
        )
        
        return authorizedRequest
    }
}
