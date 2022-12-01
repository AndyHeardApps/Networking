import XCTest
@testable import Networking

final class AuthorizingNetworkControllerTests: XCTestCase, NetworkControllerTestCase {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private var networkSession: MockNetworkSession!
    private var authorizationProvider: MockAuthorizationProvider!
    private var decoder: DataDecoder!
    private var errorHandler: MockNetworkErrorHandler!
    private(set) var universalHeaders: [String : String]!
    private var networkController: AuthorizingNetworkController<MockAuthorizationProvider>!
}

// MARK: - Setup
extension AuthorizingNetworkControllerTests {

    override func setUp() {
        super.setUp()

        self.networkSession = MockNetworkSession()
        self.errorHandler = MockNetworkErrorHandler()
        self.authorizationProvider = MockAuthorizationProvider()
        self.decoder = JSONDecoder()
        self.universalHeaders = ["headerKey2" : "universalHeaderValue2"]
        self.networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: errorHandler,
            universalHeaders: universalHeaders
        )
    }

    override func tearDown() {
        super.tearDown()

        self.networkSession = nil
        self.errorHandler = nil
        self.authorizationProvider = nil
        self.decoder = nil
        self.universalHeaders = nil
        self.networkController = nil
    }
}

// MARK: - Tests
extension AuthorizingNetworkControllerTests {

    // MARK: Request authorization
    func testFetchResponse_willSubmitRequest_toNetworkSession_withoutAuthorization_whenAuthorizationIsNotRequired() async throws {

        let request = MockNetworkRequest(requiresAuthorization: false)
        networkSession.setBlankResponse(for: request)

        _ = try await networkController.fetchResponse(request)

        let lastReceivedRequest = networkSession.receivedRequests.last?.request
        let lastReceivedBaseURL = networkSession.receivedRequests.last?.baseURL

        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders(for: request))
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
        XCTAssertEqual(lastReceivedBaseURL, baseURL)
    }

    func testFetchResponse_willUseAuthorizationProvider_toAuthorizeRequestBeforeSubmission_whenAuthorizationIsRequired() async throws {

        let request = MockNetworkRequest(requiresAuthorization: true)
        networkSession.setBlankResponse(for: request)

        _ = try await networkController.fetchResponse(request)

        let expectedHeaders = expectedHeaders(for: request, additionalHeaders: ["Authorization" : "true"])

        let lastReceivedRequest = networkSession.receivedRequests.last?.request

        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    // MARK: Transform
    func testFetchResponse_willTransformResponseUsingRequest_andReturnTransformedResponse() async throws {

        let responseData = UUID().uuidString.data(using: .utf8)!
        let responseHeaders = ["header1" : "headerValue1"]
        let expectedResponse = NetworkResponse(
            content: responseData,
            statusCode: .ok,
            headers: responseHeaders
        )

        var transformData: Data?
        var transformStatusCode: HTTPStatusCode?
        var transformDecoder: DataDecoder?
        let request = MockNetworkRequest { data, statusCode, decoder in

            transformData = data
            transformStatusCode = statusCode
            transformDecoder = decoder
            return data + data
        }

        networkSession.set(
            response: expectedResponse,
            for: request
        )

        let response = try await networkController.fetchResponse(request)

        XCTAssertEqual(transformData, expectedResponse.content)
        XCTAssertEqual(transformStatusCode, expectedResponse.statusCode)
        XCTAssertTrue(transformDecoder is JSONDecoder)

        XCTAssertEqual(response.content, responseData + responseData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response.headers, expectedResponse.headers)
    }

    // MARK: Universal headers
    func testFetchResponse_willNotAddUniversalHeaders_toRequestBeforeSubmission_whenNetworkControllerHasNoUniversalHeaders() async throws {

        let request = MockNetworkRequest(
            headers: ["headerKey2" : "headerValue2"],
            requiresAuthorization: false
        )
        networkSession.setBlankResponse(for: request)
        networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: errorHandler,
            universalHeaders: nil
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

    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_whenRequestHasExistingHeaders() async throws {

        let request = MockNetworkRequest(
            headers: ["headerKey2" : "headerValue2"],
            requiresAuthorization: false
        )
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
            headers: ["headerKey1" : "requestHeaderValue1"],
            requiresAuthorization: false
        )
        networkSession.setBlankResponse(for: request)

        _ = try await networkController.fetchResponse(request)

        let lastReceivedRequest = networkSession.receivedRequests.last?.request

        XCTAssertEqual(networkSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders(for: request))
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
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

    // MARK: Error handling
    func testFetchResponse_willThrowErrorReturnedByErrorHandler() async throws {

        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = NetworkResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        errorHandler.result = MockError()
        networkSession.set(response: response, for: request)

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertEqual(errorHandler.recievedResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedError as? HTTPStatusCode, .badRequest)
            XCTAssertTrue(error is MockError)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }
    
    func testFetchResponse_willThrowUnmodifiedError_whenErrorHandlerIsNil() async throws {

        let request = MockNetworkRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = NetworkResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        errorHandler.result = MockError()
        networkSession.set(response: response, for: request)

        networkController = AuthorizingNetworkController(
            baseURL: baseURL,
            session: networkSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: nil,
            universalHeaders: universalHeaders
        )

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertNil(errorHandler.recievedResponse)
            XCTAssertNil(errorHandler.recievedError)
            XCTAssertEqual(error as? HTTPStatusCode, .badRequest)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }


    // MARK: Error reporting
    func testFetchResponse_willReportErrorThrownByNetworkSession_withoutCallingErrorHandler() async throws {

        let request = MockNetworkRequest()
        networkSession.shouldThrowErrorOnSubmit = true

        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertNil(errorHandler.recievedError)
            XCTAssertNil(errorHandler.recievedResponse)
            XCTAssertTrue(error is MockNetworkSession.SampleError)
            XCTAssertEqual(networkSession.receivedRequests.count, 1)
        }
    }
}
