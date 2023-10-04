import XCTest
@testable import Networking

final class OAuthAuthorizationProviderTests: XCTestCase {
    
    // MARK: - Properties
    private var secureStorage: SecureStorage!
    private var authorizationProvider: OAuthAuthorizationProvider<MockAuthorizationRequest, MockReauthorizationRequest>!
}

// MARK: - Setup
extension OAuthAuthorizationProviderTests {
    
    override func setUp() {
        super.setUp()
        
        self.secureStorage = MockSecureStorage()
        self.authorizationProvider = OAuthAuthorizationProvider(storage: secureStorage)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.secureStorage = nil
        self.authorizationProvider = nil
    }
}

// MARK: - Mocks
extension OAuthAuthorizationProviderTests {
    
    private struct MockAuthorizationRequest: OAuthAuthorizationRequest {
        
        // Properties
        let httpMethod: HTTPMethod = .get
        let pathComponents: [String] = []
        let headers: [String : String]? = nil
        let queryItems: [String : String]? = nil
        let body: Data? = nil
        var shouldProvideTokens: Bool
        
        // Transform
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> Void {}
        
        // Tokens
        func accessToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "authorizationRequestAccessToken" : nil
        }
        
        func refreshToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "authorizationRequestRefreshToken" : nil
        }
    }
    
    private struct MockReauthorizationRequest: OAuthReauthorizationRequest {
        
        // Properties
        let httpMethod: HTTPMethod = .get
        let pathComponents: [String] = []
        let headers: [String : String]?
        let queryItems: [String : String]? = nil
        let body: Data? = nil
        var shouldProvideTokens: Bool
        
        // Initialiser
        init(refreshToken: String) {
            
            self.headers = ["TestRefreshToken" : refreshToken]
            self.shouldProvideTokens = true
        }
        
        // Transform
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> Void {}
        
        // Tokens
        func accessToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "reauthorizationRequestAccessToken" : nil
        }
        
        func refreshToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "reauthorizationRequestRefreshToken" : nil
        }
    }
}

// MARK: - Tests
extension OAuthAuthorizationProviderTests {
 
    func testMakeReauthorizationRequest_willReturnNil_whenNoRefreshTokenIsAvailable() {
        
        secureStorage["oauth.refreshToken"] = nil
        
        let reauthorizationRequest = authorizationProvider.makeReauthorizationRequest()
        
        XCTAssertNil(reauthorizationRequest)
    }
    
    func testMakeReauthorizationRequest_willReturnCorrectRequest_whenRefreshTokenIsAvailable() {
        
        secureStorage["oauth.refreshToken"] = "refreshToken"
        
        let reauthorizationRequest = authorizationProvider.makeReauthorizationRequest()
        
        XCTAssertNotNil(reauthorizationRequest)
        XCTAssertEqual(reauthorizationRequest?.headers, ["TestRefreshToken" : "refreshToken"])
    }
    
    func testHandleAuthorizationResponse_willExtractTokensFromResponse_andStoreInSecureStorage() {
        
        XCTAssertNil(secureStorage["oauth.accessToken"])
        XCTAssertNil(secureStorage["oauth.refreshToken"])

        let authorizationRequest = MockAuthorizationRequest(shouldProvideTokens: true)
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(authorizationResponse: response, from: authorizationRequest)
        
        XCTAssertEqual(secureStorage["oauth.accessToken"], authorizationRequest.accessToken(from: response))
        XCTAssertEqual(secureStorage["oauth.refreshToken"], authorizationRequest.refreshToken(from: response))
    }
    
    func testHandleAuthorizationResponse_willNotOverrideAndRemoveExistingTokensInSecureStorage_whenTokensAreNil() {
        
        let existingAccessToken = "existingAccessToken"
        let existingRefreshToken = "existingRefreshToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        secureStorage["oauth.refreshToken"] = existingRefreshToken
        
        let authorizationRequest = MockAuthorizationRequest(shouldProvideTokens: false)
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(authorizationResponse: response, from: authorizationRequest)
        
        XCTAssertNil(authorizationRequest.accessToken(from: response))
        XCTAssertNil(authorizationRequest.refreshToken(from: response))
        
        XCTAssertEqual(secureStorage["oauth.accessToken"], existingAccessToken)
        XCTAssertEqual(secureStorage["oauth.refreshToken"], existingRefreshToken)
    }
    
    func testHandleReauthorizationResponse_willExtractTokensFromResponse_andStoreInSecureStorage() {
        
        XCTAssertNil(secureStorage["oauth.accessToken"])
        XCTAssertNil(secureStorage["oauth.refreshToken"])

        var reauthorizationRequest = MockReauthorizationRequest(refreshToken: "")
        reauthorizationRequest.shouldProvideTokens = true
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(reauthorizationResponse: response, from: reauthorizationRequest)
        
        XCTAssertEqual(secureStorage["oauth.accessToken"], reauthorizationRequest.accessToken(from: response))
        XCTAssertEqual(secureStorage["oauth.refreshToken"], reauthorizationRequest.refreshToken(from: response))
    }
    
    func testHandleReauthorizationResponse_willNotOverrideAndRemoveExistingTokensInSecureStorage_whenTokensAreNil() {
        
        let existingAccessToken = "existingAccessToken"
        let existingRefreshToken = "existingRefreshToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        secureStorage["oauth.refreshToken"] = existingRefreshToken
        
        var reauthorizationRequest = MockReauthorizationRequest(refreshToken: "")
        reauthorizationRequest.shouldProvideTokens = false
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(reauthorizationResponse: response, from: reauthorizationRequest)
        
        XCTAssertNil(reauthorizationRequest.accessToken(from: response))
        XCTAssertNil(reauthorizationRequest.refreshToken(from: response))
        
        XCTAssertEqual(secureStorage["oauth.accessToken"], existingAccessToken)
        XCTAssertEqual(secureStorage["oauth.refreshToken"], existingRefreshToken)
    }
    
    func testAuthorizeRequest_willAddAccessTokenToRequestHeaders_whenAccessTokenIsAvailable_andRequestAlreadyHasHeaders() {
        
        let existingAccessToken = "existingAccessToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        
        let request = MockHTTPRequest(headers: ["header1" : "headerValue1"])
        XCTAssertNil(request.headers?["Authorization"])
        
        let authorizedRequest = authorizationProvider.authorize(request)
        
        XCTAssertEqual(authorizedRequest.headers?["Authorization"], "Bearer \(existingAccessToken)")
        XCTAssertEqual(authorizedRequest.httpMethod, request.httpMethod)
        XCTAssertEqual(authorizedRequest.pathComponents, request.pathComponents)
        XCTAssertEqual(authorizedRequest.headers?["header1"], "headerValue1")
        XCTAssertEqual(authorizedRequest.headers?.count, 2)
        XCTAssertEqual(authorizedRequest.queryItems, request.queryItems)
        XCTAssertEqual(authorizedRequest.body as? UUID, request.body)
        XCTAssertEqual(authorizedRequest.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testAuthorizeRequest_willAddAccessTokenToRequestHeaders_whenAccessTokenIsAvailable_andRequestHasNilHeaders() {
        
        let existingAccessToken = "existingAccessToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        
        let request = MockHTTPRequest(headers: nil)
        XCTAssertNil(request.headers?["Authorization"])
        
        let authorizedRequest = authorizationProvider.authorize(request)
        
        XCTAssertEqual(authorizedRequest.headers?["Authorization"], "Bearer \(existingAccessToken)")
        XCTAssertEqual(authorizedRequest.httpMethod, request.httpMethod)
        XCTAssertEqual(authorizedRequest.pathComponents, request.pathComponents)
        XCTAssertEqual(authorizedRequest.headers?.count, 1)
        XCTAssertEqual(authorizedRequest.queryItems, request.queryItems)
        XCTAssertEqual(authorizedRequest.body as? UUID, request.body)
        XCTAssertEqual(authorizedRequest.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testAuthorizeRequest_willReturnUnmodifiedRequest_wehnAccessTokenIsNotAvailable() {
        
        XCTAssertNil(secureStorage["oauth.accessToken"])
        
        let request = MockHTTPRequest()
        let authorizedRequest = authorizationProvider.authorize(request)

        XCTAssertEqual(authorizedRequest.httpMethod, request.httpMethod)
        XCTAssertEqual(authorizedRequest.pathComponents, request.pathComponents)
        XCTAssertEqual(authorizedRequest.headers, request.headers)
        XCTAssertEqual(authorizedRequest.queryItems, request.queryItems)
        XCTAssertEqual(authorizedRequest.body as? UUID, request.body)
        XCTAssertEqual(authorizedRequest.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testInit_willUseKeychainBackedStorage() {
        
        authorizationProvider = OAuthAuthorizationProvider()
        
        XCTAssertTrue(authorizationProvider.storage is KeychainSecureStorage)
    }
}
