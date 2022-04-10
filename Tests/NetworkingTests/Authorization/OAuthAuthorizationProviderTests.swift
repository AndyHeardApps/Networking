import XCTest
@testable import Networking

final class OAuthAuthorizationProviderTests: XCTestCase {
    
    // MARK: - Properties
    private var storage: MockStorage!
    private var authorizationProvider: OAuthAuthorizationProvider<MockOAuthAuthorizationRequest, MockOAuthReauthorizationRequest>!
}

// MARK: - Setup
extension OAuthAuthorizationProviderTests {
    
    override func setUp() {
        super.setUp()
        
        storage = MockStorage()
        authorizationProvider = OAuthAuthorizationProvider(storage: storage)
    }
    
    override func tearDown() {
        super.tearDown()
        
        storage = nil
        authorizationProvider = nil
    }
}

// MARK: - Mocks
extension OAuthAuthorizationProviderTests {
    
    private final class MockStorage: SecureStorage {
        
        private var storage: [String : String] = [:]
        
        subscript(key: String) -> String? {
            get { storage[key] }
            set { storage[key] = newValue }
        }
    }
    
    private struct MockOAuthAuthorizationRequest: OAuthAuthorizationRequest {
        
        let httpMethod: HTTPMethod
        let pathComponents: [String]
        let headers: [String : String]?
        let queryItems: [String : String]?
        let body: Data?
        let requiresAuthorization: Bool
        
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws -> MockOAuthAuthorizationRequestResponse {
            
            .init(accessToken: "authorizationAccessToken", refreshToken: "authorizationRefreshToken")
        }
    }
    
    private struct MockOAuthReauthorizationRequest: OAuthReauthorizationRequest {
        
        let httpMethod: HTTPMethod
        let pathComponents: [String]
        let headers: [String : String]?
        let queryItems: [String : String]?
        let body: Data?
        
        init(refreshToken: String) {
            
            self.httpMethod = .get
            self.pathComponents = ["path"]
            self.headers = [:]
            self.queryItems = nil
            self.body = nil
        }
        
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws -> MockOAuthAuthorizationRequestResponse {
            
            .init(accessToken: "reauthorizationAccessToken", refreshToken: "reauthorizationRefreshToken")
        }
    }
    
    private struct MockOAuthAuthorizationRequestResponse: OAuthAuthorizationRequestResponse {
        
        let accessToken: String
        let refreshToken: String
    }
}

// MARK: - Tests
extension OAuthAuthorizationProviderTests {

    func testMakeReauthorizationRequest_willReturnNil_whenRefreshTokenIsNotAvailable() {
        
        storage[OAuthAuthorizationProviderStorageKey.refreshToken] = nil
        XCTAssertNil(authorizationProvider.makeReauthorizationRequest())
    }
    
    func testMakeReauthorizationRequest_willNotReturnNil_whenRefreshTokenIsAvailable() {
        
        storage[OAuthAuthorizationProviderStorageKey.refreshToken] = "someRefreshKey"
        XCTAssertNotNil(authorizationProvider.makeReauthorizationRequest())
    }
    
    func testHandleAuthorizationResponse_willStoreTokensInStorage() {
        
        let responseContent = MockOAuthAuthorizationRequestResponse(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString
        )
        let response = NetworkResponse(
            content: responseContent,
            statusCode: .ok,
            headers: [:]
        )
        
        XCTAssertNil(storage[OAuthAuthorizationProviderStorageKey.accessToken])
        XCTAssertNil(storage[OAuthAuthorizationProviderStorageKey.refreshToken])
        
        authorizationProvider.handle(authorizationResponse: response)
        
        XCTAssertEqual(storage[OAuthAuthorizationProviderStorageKey.accessToken], responseContent.accessToken)
        XCTAssertEqual(storage[OAuthAuthorizationProviderStorageKey.refreshToken], responseContent.refreshToken)
    }

    func testHandleReauthorizationResponse_willStoreTokensInStorage() {
        
        let responseContent = MockOAuthAuthorizationRequestResponse(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString
        )
        let response = NetworkResponse(
            content: responseContent,
            statusCode: .ok,
            headers: [:]
        )
        
        XCTAssertNil(storage[OAuthAuthorizationProviderStorageKey.accessToken])
        XCTAssertNil(storage[OAuthAuthorizationProviderStorageKey.refreshToken])
        
        authorizationProvider.handle(reauthorizationResponse: response)
        
        XCTAssertEqual(storage[OAuthAuthorizationProviderStorageKey.accessToken], responseContent.accessToken)
        XCTAssertEqual(storage[OAuthAuthorizationProviderStorageKey.refreshToken], responseContent.refreshToken)
    }
    
    func testAuthorizeRequest_willAddAccessTokenToHeaders_whenExistingHeadersAreNil_andAccessTokenIsAvailable() {
        
        let request = AnyRequest(
            httpMethod: .connect,
            pathComponents: [UUID().uuidString, UUID().uuidString],
            headers: nil,
            queryItems: [UUID().uuidString : UUID().uuidString],
            body: UUID().uuidString.data(using: .utf8),
            requiresAuthorization: true,
            transform: { _, _, _ in }
        )
        
        let accessToken = UUID().uuidString
        storage[OAuthAuthorizationProviderStorageKey.accessToken] = accessToken
        
        let authorizedRequest = authorizationProvider.authorize(request)
        XCTAssertEqual(authorizedRequest.headers?[OAuthAuthorizationProviderStorageKey.authorizationHeader], accessToken)
    }
    
    func testAuthorizeRequest_willAddAccessTokenToHeaders_whenExistingHeadersAreNotNil_andAccessTokenIsAvailable() {
        
        let request = AnyRequest(
            httpMethod: .connect,
            pathComponents: [UUID().uuidString, UUID().uuidString],
            headers: [UUID().uuidString : UUID().uuidString],
            queryItems: [UUID().uuidString : UUID().uuidString],
            body: UUID().uuidString.data(using: .utf8),
            requiresAuthorization: true
        ) { _, _, _ in }
        
        let accessToken = UUID().uuidString
        storage[OAuthAuthorizationProviderStorageKey.accessToken] = accessToken
        
        let authorizedRequest = authorizationProvider.authorize(request)
        XCTAssertEqual(authorizedRequest.headers?[OAuthAuthorizationProviderStorageKey.authorizationHeader], accessToken)
    }
    
    func testAuthorizeRequest_willNotAddAccessTokenToHeaders_whenAccessTokenIsNotAvailable() {
        
        let request = AnyRequest(
            httpMethod: .connect,
            pathComponents: [UUID().uuidString, UUID().uuidString],
            headers: [UUID().uuidString : UUID().uuidString],
            queryItems: [UUID().uuidString : UUID().uuidString],
            body: UUID().uuidString.data(using: .utf8),
            requiresAuthorization: true
        ) { _, _, _ in }
        
        storage[OAuthAuthorizationProviderStorageKey.accessToken] = nil
        
        let authorizedRequest = authorizationProvider.authorize(request)
        XCTAssertNil(authorizedRequest.headers?[OAuthAuthorizationProviderStorageKey.authorizationHeader])
    }
}
