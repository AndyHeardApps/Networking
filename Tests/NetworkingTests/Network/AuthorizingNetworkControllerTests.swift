import XCTest
@testable import Networking

final class AuthorizingNetworkControllerTests: XCTestCase {
    
    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private var networkSession: MockNetworkSession!
    private var authorizationProvider: MockAuthorizationProvider!
    private var jsonDecoder: JSONDecoder!
    private var networkController: AuthorizingNetworkController<MockAuthorizationProvider>!
    private var customErrorHandlerWasCalled = false
}

// MARK: - Setup
extension AuthorizingNetworkControllerTests {
    
    override func setUp() {
        super.setUp()
        
        self.networkSession = MockNetworkSession()
        self.authorizationProvider = MockAuthorizationProvider()
        self.jsonDecoder = JSONDecoder()
        self.networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            authorization: authorizationProvider,
            jsonDecoder: jsonDecoder
        )
        self.customErrorHandlerWasCalled = false
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.networkSession = nil
        self.authorizationProvider = nil
        self.jsonDecoder = nil
        self.networkController = nil
        self.customErrorHandlerWasCalled = false
    }
}

// MARK: - Custom error handler setup
extension AuthorizingNetworkControllerTests {
    
    struct CustomError: LocalizedError, Decodable {
        
        let errorDescription: String?
    }
    
    private func setNetworkControllerWithCustomErrorHandler() {
        
        networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            authorization: authorizationProvider,
            jsonDecoder: jsonDecoder
        ) { [jsonDecoder, weak self] response, error in
            
            self?.customErrorHandlerWasCalled = true
            switch error {
            case HTTPStatusCode.badRequest:
                let customError = try jsonDecoder!.decode(CustomError.self, from: response.content)
                throw customError
                
            case HTTPStatusCode.unauthorized:
                return true
                
            default:
                return false
                
            }
        }
    }
}

// MARK: - Tests
extension AuthorizingNetworkControllerTests {
    
    // MARK: Request authorization
    func testFetchResponse_willSubmitRequest_toNetworkSession_withoutAlteration_whenAuthorizationIsNotRequired() async throws {
        
        let request = MockNetworkRequest(requiresAuthorization: false)
        networkSession.setBlankResponse(for: request)

        _ = try await networkController.fetchResponse(request)
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        let lastReceivedBaseURL = networkSession.receivedRequests.last?.baseURL
        
        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, request.headers)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
        XCTAssertEqual(lastReceivedBaseURL, baseURL)
    }
    
    func testFetchResponse_willUseAuthorizationProvider_toAuthorizeRequestBeforeSubmission_whenAuthorizationIsRequired() async throws {
        
        let request = MockNetworkRequest()
        networkSession.setBlankResponse(for: request)

        _ = try await networkController.fetchResponse(request)
        
        var expectedHeaders = request.headers ?? [:]
        expectedHeaders["Authorization"] = "true"
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request

        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willNotAuthenticateOrReauthenticateRequests_whenEmptyAuthorizationProviderIsUsed() async throws {
        
        let request = MockNetworkRequest(requiresAuthorization: true)
        networkSession.setBlankResponse(for: request)

        let networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            jsonDecoder: jsonDecoder
        )

        _ = try await networkController.fetchResponse(request)
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request

        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, request.headers)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    // MARK: Transform
    func testFetchResponse_willTransformResponseUsingRequestFromNetworkSession_andReturnTransformedResponse() async throws {
        
        let responseData = UUID().uuidString.data(using: .utf8)!
        let responseHeaders = ["header1" : "headerValue1"]
        let expectedResponse = NetworkResponse(
            content: responseData,
            statusCode: .ok,
            headers: responseHeaders
        )
        
        var transformData: Data?
        var transformStatusCode: HTTPStatusCode?
        var transformJsonDecoder: JSONDecoder?
        let request = MockNetworkRequest { data, statusCode, jsonDecoder in
            
            transformData = data
            transformStatusCode = statusCode
            transformJsonDecoder = jsonDecoder
            return data + data
        }
        
        networkSession.set(
            response: expectedResponse,
            for: request
        )
        
        let response = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(transformData, expectedResponse.content)
        XCTAssertEqual(transformStatusCode, expectedResponse.statusCode)
        XCTAssertTrue(transformJsonDecoder === jsonDecoder)
        
        XCTAssertEqual(response.content, responseData + responseData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response.headers, expectedResponse.headers)
    }
    
    // MARK: Universal headers
    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_whenRequestHasExistingHeaders() async throws {
        
        let request = MockNetworkRequest(
            headers: ["header1" : "headerValue1"],
            requiresAuthorization: false
        )
        networkController.universalHeaders = ["universalHeader1" : "universalHeaderValue1"]
        networkSession.setBlankResponse(for: request)
        
        _ = try await networkController.fetchResponse(request)
        
        let expectedHeaders = networkController.universalHeaders!.merging(request.headers!) { $1 }
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        
        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_whenRequestHasNoExistingHeaders() async throws {
        
        let request = MockNetworkRequest(
            headers: nil,
            requiresAuthorization: false
        )
        networkController.universalHeaders = ["universalHeader1" : "universalHeaderValue1"]
        networkSession.setBlankResponse(for: request)
        
        _ = try await networkController.fetchResponse(request)
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        
        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, networkController.universalHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_andPrioritiseRequestHeadersOnConflict() async throws {
        
        let request = MockNetworkRequest(
            headers: ["header1" : "requestHeaderValue1"],
            requiresAuthorization: false
        )
        networkController.universalHeaders = ["header1" : "universalHeaderValue1"]
        networkSession.setBlankResponse(for: request)
        
        _ = try await networkController.fetchResponse(request)
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        
        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, request.headers)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testFetchResponse_willAddUniversalHeaders_toReauthorizationRequestBeforeSubmission() async throws {
        
        let request = MockNetworkRequest(requiresAuthorization: true) { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        networkSession.setBlankResponse(for: request)
        networkSession.setReauthorizationResponse()
        networkController.universalHeaders = ["header1" : "universalHeaderValue1"]

        _ = try await networkController.fetchResponse(request)

        let lastReceivedRequest = networkSession.receivedRequests.dropFirst().first?.request
        
        XCTAssertEqual(networkSession.receivedRequests.count, 3)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, ["mockReauthorization"])
        XCTAssertEqual(lastReceivedRequest?.headers?["header1"], "universalHeaderValue1")
    }
    
    // MARK: Access token saving
    func testFetchResponse_willSaveAccessToken_whenPossible() async throws {
        
        let accessToken = MockAccessToken(value: "accessToken")
        let request = MockNetworkRequest { _, _, _ in
            accessToken
        }
        networkSession.setBlankResponse(for: request)
                
        _ = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(authorizationProvider.handledAuthorizationResponse?.content, accessToken)
    }
    
    func testFetchResponse_willSaveRefreshToken_whenPossible() async throws {
        
        let refreshToken = MockRefreshToken(value: "refreshToken")
        let request = MockNetworkRequest { _, _, _ in
            refreshToken
        }
        networkSession.setBlankResponse(for: request)
        
        _ = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(authorizationProvider.handledReauthorizationResponse?.content, refreshToken)
    }
    
    // MARK: Reauthorization
    func testFetchResponse_willUseAuthorizationProvider_toReauthorizeRequest_whenFirstAttemptThrowsUnauthorizedStatusCode_andRetryRequestIsSuccessfullyCreated() async throws {
        
        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        networkSession.setBlankResponse(for: request)
        networkSession.setReauthorizationResponse()
        
        _ = try await networkController.fetchResponse(request)
        
        var expectedHeaders = request.headers ?? [:]
        expectedHeaders["Authorization"] = "true"
        
        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        
        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertEqual(networkSession.receivedRequests.count, 3)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willUseAuthorizationProvider_toReauthorizeRequest_whenFirstAttemptIsUnauthorized_andThrowsErrorIfReauthorizationFails() async throws {
        
        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = false
        networkSession.setBlankResponse(for: request)

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? HTTPStatusCode, .unauthorized)
        }
    }
    
    func testFetchResponse_willReauthorizeFailedRequest_whenCustomErrorHandlerReturnsTrue() async throws {
        
        setNetworkControllerWithCustomErrorHandler()
        
        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        authorizationProvider.shouldMakeReauthorizationRequest = true
        networkSession.set(
            response: .init(
                content: .init(),
                statusCode: .unauthorized, // Triggers `true` response in custom closure
                headers: [:]
            ),
            for: request
        )
        networkSession.setReauthorizationResponse()

        _ = try? await networkController.fetchResponse(request)
        
        XCTAssertTrue(customErrorHandlerWasCalled)
        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertEqual(networkSession.receivedRequests.count, 3)
    }
    
    func testFetchResponse_willThrowUnmodifiedError_whenCustomErrorHandlerReturnsFalse() async throws {
        
        setNetworkControllerWithCustomErrorHandler()
        
        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        networkSession.set(
            response: .init(
                content: .init(),
                statusCode: .unprocessableEntity, // Triggers `false` response in custom closure
                headers: [:]
            ),
            for: request
        )

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
                 
            XCTAssertTrue(customErrorHandlerWasCalled)
            XCTAssertEqual(error as? HTTPStatusCode, .unprocessableEntity)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }
    
    func testFetchResponse_willThrowModifiedError_thrownByCustomErrorHandler() async throws {
        
        setNetworkControllerWithCustomErrorHandler()
        
        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let responseData = try JSONEncoder().encode(["errorDescription" : "Error message"])
        networkSession.set(
            response: .init(
                content: responseData,
                statusCode: .badRequest, // Triggers custom error decoding
                headers: [:]
            ),
            for: request
        )

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
                    
            XCTAssertTrue(customErrorHandlerWasCalled)
            XCTAssertTrue(error is CustomError)
            XCTAssertEqual(error.localizedDescription, "Error message")
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }
    
    // MARK: Error reporting
    func testFetchResponse_willReportErrorThrownByNetworkSession_withoutCallingErrorHandler() async throws {
        
        setNetworkControllerWithCustomErrorHandler()

        let request = MockNetworkRequest()
        networkSession.shouldThrowErrorOnSubmit = true
        
        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
                    
            XCTAssertFalse(customErrorHandlerWasCalled)
            XCTAssertTrue(error is MockNetworkSession.SampleError)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }

    // MARK: Fetch content
    func testFetchContent_willReturnContent_thatMatchesFetchRequestResponse() async throws {
        
        let responseContent = "content"
        let request = MockNetworkRequest { data, _, _ in
            String(data: data, encoding: .utf8)!
        }
        
        networkSession.set(data: responseContent.data(using: .utf8)!, for: request)
     
        let content = try await networkController.fetchContent(request)
        let response = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(content, responseContent)
        XCTAssertEqual(content, response.content)
    }
}
