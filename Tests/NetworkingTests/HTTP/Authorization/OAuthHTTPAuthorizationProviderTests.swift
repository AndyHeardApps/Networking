import Foundation
import Testing
@testable import Networking

@Suite(
    "OAuth HTTP authorization provider",
    .tags(.http)
)
struct OAuthHTTPAuthorizationProviderTests {

    // MARK: - Properties
    private let secureStorage: SecureStorage
    private let authorizationProvider: OAuthHTTPAuthorizationProvider<MockAuthorizationRequest, MockReauthorizationRequest>

    // MARK: - Initializer
    init() {

        self.secureStorage = MockSecureStorage()
        self.authorizationProvider = OAuthHTTPAuthorizationProvider(storage: secureStorage)
    }
}

// MARK: - Mocks
extension OAuthHTTPAuthorizationProviderTests {
    
    private struct MockAuthorizationRequest: OAuthHTTPAuthorizationRequest {
        
        // Properties
        let httpMethod: HTTPMethod = .get
        let pathComponents: [String] = []
        var shouldProvideTokens: Bool
        
        // Decode
        func decode(data: Data, statusCode: HTTPStatusCode, using coders: DataCoders) throws -> () {}
        
        // Tokens
        func accessToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "authorizationRequestAccessToken" : nil
        }
        
        func refreshToken(from response: HTTPResponse<Void>) -> String? {
            shouldProvideTokens ? "authorizationRequestRefreshToken" : nil
        }
    }
    
    private struct MockReauthorizationRequest: OAuthHTTPReauthorizationRequest {
        
        // Properties
        let httpMethod: HTTPMethod = .get
        let pathComponents: [String] = []
        let headers: [String : String]?
        var shouldProvideTokens: Bool
        
        // Initialiser
        init(refreshToken: String) {
            
            self.headers = ["TestRefreshToken" : refreshToken]
            self.shouldProvideTokens = true
        }
        
        // Decode
        func decode(data: Data, statusCode: HTTPStatusCode, using coders: DataCoders) throws -> () {}
        
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
extension OAuthHTTPAuthorizationProviderTests {

    @Test("makeReauthorizationRequest returns nil when no refresh token is available")
    func makReauthorizationRequestReturnsNilWhenNoRefreshTokenIsAvailable() {

        secureStorage["oauth.refreshToken"] = nil

        let reauthorizationRequest = authorizationProvider.makeReauthorizationRequest()

        #expect(reauthorizationRequest == nil)
    }

    @Test("makeReauthorizationRequest returns request when refresh token is available")
    func makeReauthorizationRequestReturnsRequestWhenRefreshTokenIsAvailable() {

        secureStorage["oauth.refreshToken"] = "refreshToken"

        let reauthorizationRequest = authorizationProvider.makeReauthorizationRequest()

        #expect(reauthorizationRequest != nil)
        #expect(reauthorizationRequest?.headers == ["TestRefreshToken" : "refreshToken"])
    }

    @Test("handleAuthorizationResponse extracts and stores tokens in authorization response")
    func handleAuthorizationResponseExtractsAndStoresTokensInAuthorizationResponse() {

        #expect(secureStorage["oauth.accessToken"] == nil)
        #expect(secureStorage["oauth.refreshToken"] == nil)

        let authorizationRequest = MockAuthorizationRequest(shouldProvideTokens: true)

        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(authorizationResponse: response, from: authorizationRequest)

        #expect(secureStorage["oauth.accessToken"] == authorizationRequest.accessToken(from: response))
        #expect(secureStorage["oauth.refreshToken"] == authorizationRequest.refreshToken(from: response))
    }

    @Test("handleAuthorizationResponse does not overwrite existing tokens with nil")
    func handleAuthorizationResponseDoesNotOverwriteExistingTokensWithNil() {

        let existingAccessToken = "existingAccessToken"
        let existingRefreshToken = "existingRefreshToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        secureStorage["oauth.refreshToken"] = existingRefreshToken

        let authorizationRequest = MockAuthorizationRequest(shouldProvideTokens: false)

        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(authorizationResponse: response, from: authorizationRequest)

        #expect(authorizationRequest.accessToken(from: response) == nil)
        #expect(authorizationRequest.refreshToken(from: response) == nil)

        #expect(secureStorage["oauth.accessToken"] == existingAccessToken)
        #expect(secureStorage["oauth.refreshToken"] == existingRefreshToken)
    }

    @Test("handleReauthorizationResponse extracts and stores tokens in authorization response")
    func handleReauthorizationResponseExtractsAndStoresTokensInAuthorizationResponse() {

        #expect(secureStorage["oauth.accessToken"] == nil)
        #expect(secureStorage["oauth.refreshToken"] == nil)

        var reauthorizationRequest = MockReauthorizationRequest(refreshToken: "")
        reauthorizationRequest.shouldProvideTokens = true
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(reauthorizationResponse: response, from: reauthorizationRequest)
        
        #expect(secureStorage["oauth.accessToken"] == reauthorizationRequest.accessToken(from: response))
        #expect(secureStorage["oauth.refreshToken"] == reauthorizationRequest.refreshToken(from: response))
    }
    
    @Test("handleReauthorizationResponse does not overwrite existing tokens with nil")
    func handleReauthorizationResponseDoesNotOverwriteExistingTokensWithNil() {

        let existingAccessToken = "existingAccessToken"
        let existingRefreshToken = "existingRefreshToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        secureStorage["oauth.refreshToken"] = existingRefreshToken
        
        var reauthorizationRequest = MockReauthorizationRequest(refreshToken: "")
        reauthorizationRequest.shouldProvideTokens = false
        
        let response = HTTPResponse(content: (), statusCode: .ok, headers: [:])
        authorizationProvider.handle(reauthorizationResponse: response, from: reauthorizationRequest)
        
        #expect(reauthorizationRequest.accessToken(from: response) == nil)
        #expect(reauthorizationRequest.refreshToken(from: response) == nil)

        #expect(secureStorage["oauth.accessToken"] == existingAccessToken)
        #expect(secureStorage["oauth.refreshToken"] == existingRefreshToken)
    }
    
    @Test("authorizeRequest adds access token to existing headers")
    func authorizeRequestAddsAccessTokenToExistingHeaders() {

        let existingAccessToken = "existingAccessToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        
        let request = MockHTTPRequest(headers: ["header1" : "headerValue1"])
        #expect(request.headers?["Authorization"] == nil)

        let authorizedRequest = authorizationProvider.authorize(request)
        
        #expect(authorizedRequest.headers?["Authorization"] == "Bearer \(existingAccessToken)")
        #expect(authorizedRequest.httpMethod == request.httpMethod)
        #expect(authorizedRequest.pathComponents == request.pathComponents)
        #expect(authorizedRequest.headers?["header1"] == "headerValue1")
        #expect(authorizedRequest.headers?.count == 2)
        #expect(authorizedRequest.queryItems == request.queryItems)
        #expect(authorizedRequest.body == request.body)
        #expect(authorizedRequest.requiresAuthorization == request.requiresAuthorization)
    }
    
    @Test("authorizeRequest adds access token to nil headers")
    func authorizeRequestAddsAccessTokenToNilHeaders() {

        let existingAccessToken = "existingAccessToken"
        secureStorage["oauth.accessToken"] = existingAccessToken
        
        let request = MockHTTPRequest(headers: nil)
        #expect(request.headers?["Authorization"] == nil)

        let authorizedRequest = authorizationProvider.authorize(request)
        
        #expect(authorizedRequest.headers?["Authorization"] == "Bearer \(existingAccessToken)")
        #expect(authorizedRequest.httpMethod == request.httpMethod)
        #expect(authorizedRequest.pathComponents == request.pathComponents)
        #expect(authorizedRequest.headers?.count == 1)
        #expect(authorizedRequest.queryItems == request.queryItems)
        #expect(authorizedRequest.body == request.body)
        #expect(authorizedRequest.requiresAuthorization == request.requiresAuthorization)
    }

    @Test("authorizeRequest returns original request when token not available")
    func authorizeRequestReturnsOriginalRequestWhenTokenNotAvailable() {

        #expect(secureStorage["oauth.accessToken"] == nil)

        let request = MockHTTPRequest()
        let authorizedRequest = authorizationProvider.authorize(request)

        #expect(authorizedRequest.httpMethod == request.httpMethod)
        #expect(authorizedRequest.pathComponents == request.pathComponents)
        #expect(authorizedRequest.headers == request.headers)
        #expect(authorizedRequest.queryItems == request.queryItems)
        #expect(authorizedRequest.body == request.body)
        #expect(authorizedRequest.requiresAuthorization == request.requiresAuthorization)
    }
    
    @Test("authorizeRequest returns original request when authorization is not required")
    func authorizeRequestReturnsOriginalRequestWhenAuthorizationIsNotRequired() {
        
        let existingAccessToken = "existingAccessToken"
        secureStorage["oauth.accessToken"] = existingAccessToken

        #expect(secureStorage["oauth.accessToken"] != nil)
        
        let request = MockHTTPRequest(requiresAuthorization: false)
        let authorizedRequest = authorizationProvider.authorize(request)

        #expect(authorizedRequest.httpMethod == request.httpMethod)
        #expect(authorizedRequest.pathComponents == request.pathComponents)
        #expect(authorizedRequest.headers == request.headers)
        #expect(authorizedRequest.queryItems == request.queryItems)
        #expect(authorizedRequest.body == request.body)
        #expect(authorizedRequest.requiresAuthorization == request.requiresAuthorization)
    }

    @Test("Default initializer uses Keychain backed storage")
    func defaultInitializerUsesKeychainBackedStorage() {

        let authorizationProvider = OAuthHTTPAuthorizationProvider<MockAuthorizationRequest, MockReauthorizationRequest>()
        
        #expect(authorizationProvider.storage is KeychainSecureStorage)
    }
}
