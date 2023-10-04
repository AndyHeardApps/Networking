import XCTest
@testable import Networking

final class ReauthorizingHTTPControllerTests: XCTestCase, HTTPControllerTestCase {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private let reauthorizationBaseURL = URL(string: "https://reauth.domain.com")!
    private var httpSession: MockHTTPSession!
    private var authorizationProvider: MockReauthorizationProvider!
    private var decoder: DataDecoder!
    private var errorHandler: MockReauthorizationHTTPErrorHandler!
    private(set) var universalHeaders: [String : String]!
    private var httpController: ReauthorizingHTTPController<MockReauthorizationProvider>!
}

// MARK: - Setup
extension ReauthorizingHTTPControllerTests {

    override func setUp() {
        super.setUp()

        self.httpSession = MockHTTPSession()
        self.errorHandler = MockReauthorizationHTTPErrorHandler()
        self.authorizationProvider = MockReauthorizationProvider()
        self.decoder = JSONDecoder()
        self.universalHeaders = ["headerKey2" : "universalHeaderValue2"]
        self.httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            reauthorizationBaseURL: reauthorizationBaseURL,
            session: httpSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: errorHandler,
            universalHeaders: universalHeaders
        )
    }

    override func tearDown() {
        super.tearDown()

        self.httpSession = nil
        self.errorHandler = nil
        self.authorizationProvider = nil
        self.decoder = nil
        self.universalHeaders = nil
        self.httpController = nil
    }
}

// MARK: - Tests
extension ReauthorizingHTTPControllerTests {

    // MARK: Request authorization
    func testFetchResponse_willSubmitRequest_toHTTPSession_withoutAuthorization_whenAuthorizationIsNotRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: false)
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request
        let lastReceivedBaseURL = httpSession.receivedRequests.last?.baseURL

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders(for: request))
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
        XCTAssertEqual(lastReceivedBaseURL, baseURL)
    }

    func testFetchResponse_willUseAuthorizationProvider_toAuthorizeRequestBeforeSubmission_whenAuthorizationIsRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: true)
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let expectedHeaders = expectedHeaders(for: request, additionalHeaders: ["Authorization" : "true"])

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    // MARK: Transform
    func testFetchResponse_willTransformResponseUsingRequest_andReturnTransformedResponse() async throws {

        let responseData = UUID().uuidString.data(using: .utf8)!
        let responseHeaders = ["header1" : "headerValue1"]
        let expectedResponse = HTTPResponse(
            content: responseData,
            statusCode: .ok,
            headers: responseHeaders
        )

        var transformData: Data?
        var transformStatusCode: HTTPStatusCode?
        var transformDecoder: DataDecoder?
        let request = MockHTTPRequest { data, statusCode, decoder in

            transformData = data
            transformStatusCode = statusCode
            transformDecoder = decoder
            return data + data
        }

        httpSession.set(
            response: expectedResponse,
            for: request
        )

        let response = try await httpController.fetchResponse(request)

        XCTAssertEqual(transformData, expectedResponse.content)
        XCTAssertEqual(transformStatusCode, expectedResponse.statusCode)
        XCTAssertTrue(transformDecoder is JSONDecoder)

        XCTAssertEqual(response.content, responseData + responseData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response.headers, expectedResponse.headers)
    }

    // MARK: Universal headers
    func testFetchResponse_willNotAddUniversalHeaders_toRequestBeforeSubmission_whenHTTPControllerHasNoUniversalHeaders() async throws {

        let request = MockHTTPRequest(
            headers: ["headerKey2" : "headerValue2"],
            requiresAuthorization: false
        )
        httpSession.setBlankResponse(for: request)
        httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            session: httpSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: errorHandler,
            universalHeaders: nil
        )

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, request.headers)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_whenRequestHasExistingHeaders() async throws {

        let request = MockHTTPRequest(
            headers: ["headerKey2" : "headerValue2"],
            requiresAuthorization: false
        )
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let expectedHeaders = httpController.universalHeaders!.merging(request.headers!) { $1 }

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_whenRequestHasNoExistingHeaders() async throws {

        let request = MockHTTPRequest(
            headers: nil,
            requiresAuthorization: false
        )
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, httpController.universalHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willAddUniversalHeaders_toRequestBeforeSubmission_andPrioritiseRequestHeadersOnConflict() async throws {

        let request = MockHTTPRequest(
            headers: ["headerKey1" : "requestHeaderValue1"],
            requiresAuthorization: false
        )
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders(for: request))
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    func testFetchResponse_willAddUniversalHeaders_toReauthorizationRequestBeforeSubmission() async throws {

        let request = MockHTTPRequest(requiresAuthorization: true) { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        httpSession.setBlankResponse(for: request)
        httpSession.setReauthorizationResponse()

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.dropFirst().first?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 3)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, ["mockReauthorization"])
        XCTAssertEqual(lastReceivedRequest?.headers?["headerKey2"], "universalHeaderValue2")
    }

    // MARK: Access token saving
    func testFetchResponse_willSaveAccessToken_whenPossible() async throws {

        let accessToken = MockAccessToken(value: "accessToken")
        let request = MockHTTPRequest { _, _, _ in
            accessToken
        }
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        XCTAssertEqual(authorizationProvider.handledAuthorizationResponse?.content, accessToken)
    }

    func testFetchResponse_willSaveRefreshToken_whenPossible() async throws {

        let refreshToken = MockRefreshToken(value: "refreshToken")
        let request = MockHTTPRequest { _, _, _ in
            refreshToken
        }
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        XCTAssertEqual(authorizationProvider.handledReauthorizationResponse?.content, refreshToken)
    }

    // MARK: Reauthorization
    func testFetchResponse_willReauthorizeFailedRequest_whenErrorHandlerReturnsAttemptReauthorization() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .ok,
            headers: [:]
        )
        errorHandler.shouldAttemptReauthorizationResult = true
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        httpSession.set(response: response, for: request)
        httpSession.setReauthorizationResponse()

        _ = try? await httpController.fetchResponse(request)

        XCTAssertEqual(errorHandler.recievedAttemptReauthorizationResponse?.content.isEmpty, true)
        XCTAssertEqual(errorHandler.recievedAttemptReauthorizationError as? HTTPStatusCode, .unauthorized)
        XCTAssertNil(errorHandler.recievedMappingResponse)
        XCTAssertNil(errorHandler.recievedMappingError)
        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertEqual(httpSession.receivedRequests.count, 3)
        XCTAssertEqual(httpSession.receivedRequests.first?.baseURL, baseURL)
        XCTAssertEqual(httpSession.receivedRequests.dropFirst().first?.baseURL, reauthorizationBaseURL)
        XCTAssertEqual(httpSession.receivedRequests.last?.baseURL, baseURL)
    }

    func testFetchResponse_willThrowErrorReturnedByErrorHandler_whenInitialRequestFails() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        errorHandler.shouldAttemptReauthorizationResult = false
        errorHandler.mapResult = MockError()
        httpSession.set(response: response, for: request)

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertEqual(errorHandler.recievedAttemptReauthorizationResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedAttemptReauthorizationError as? HTTPStatusCode, .badRequest)
            XCTAssertEqual(errorHandler.recievedMappingResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedMappingError as? HTTPStatusCode, .badRequest)
            XCTAssertTrue(error is MockError)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }

    func testFetchResponse_willThrowErrorReturnedByErrorHandler_whenRetriedRequestFails() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        errorHandler.shouldAttemptReauthorizationResult = true
        errorHandler.mapResult = MockError()
        httpSession.set(response: response, for: request)
        httpSession.setReauthorizationResponse()

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertEqual(errorHandler.recievedAttemptReauthorizationResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedAttemptReauthorizationError as? HTTPStatusCode, .badRequest)
            XCTAssertEqual(errorHandler.recievedMappingResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedMappingError as? HTTPStatusCode, .badRequest)
            XCTAssertTrue(error is MockError)
            XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(httpSession.receivedRequests.count, 3)
        }
    }

    func testFetchResponse_willUseAuthorizationProvider_toReauthorizeRequest_whenFirstAttemptThrowsUnauthorizedStatusCode_andErrorHandlerIsNil_andRetryRequestIsSuccessfullyCreated() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }

        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        httpSession.setBlankResponse(for: request)
        httpSession.setReauthorizationResponse()
        
        httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            session: httpSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: nil,
            universalHeaders: universalHeaders
        )

        _ = try await httpController.fetchResponse(request)

        let expectedHeaders = expectedHeaders(for: request, additionalHeaders: ["Authorization" : "true"])

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertEqual(httpSession.receivedRequests.count, 3)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? UUID, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testFetchResponse_willUseAuthorizationProvider_toReauthorizeRequest_whenFirstAttemptThrowsUnauthorizedStatusCode_andErrorHandlerIsNil_andThrowsErrorIfReauthorizationFails() async throws {
        
        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = false
        httpSession.setBlankResponse(for: request)
        
        httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            session: httpSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: nil,
            universalHeaders: universalHeaders
        )

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? HTTPStatusCode, .unauthorized)
        }
    }

    func testFetchResponse_willThrowUnmodifiedError_whenErrorHandlerIsNil() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        httpSession.set(response: response, for: request)

        httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            session: httpSession,
            authorization: authorizationProvider,
            decoder: decoder,
            errorHandler: nil,
            universalHeaders: universalHeaders
        )

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertNil(errorHandler.recievedAttemptReauthorizationResponse)
            XCTAssertNil(errorHandler.recievedAttemptReauthorizationError)
            XCTAssertNil(errorHandler.recievedMappingResponse)
            XCTAssertNil(errorHandler.recievedMappingError)
            XCTAssertEqual(error as? HTTPStatusCode, .badRequest)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }

    // MARK: Error reporting
    func testFetchResponse_willReportErrorThrownByHTTPSession_withoutCallingErrorHandler() async throws {

        let request = MockHTTPRequest()
        httpSession.shouldThrowErrorOnSubmit = true

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertNil(errorHandler.recievedAttemptReauthorizationResponse)
            XCTAssertNil(errorHandler.recievedAttemptReauthorizationError)
            XCTAssertNil(errorHandler.recievedMappingResponse)
            XCTAssertNil(errorHandler.recievedMappingError)
            XCTAssertTrue(error is MockHTTPSession.SampleError)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }
}
