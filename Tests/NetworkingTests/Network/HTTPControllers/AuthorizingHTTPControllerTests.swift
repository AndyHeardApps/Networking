import XCTest
@testable import Networking

final class AuthorizingHTTPControllerTests: XCTestCase, HTTPControllerTestCase {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private var httpSession: MockHTTPSession!
    private var authorizationProvider: MockAuthorizationProvider!
    private var decoder: DataDecoder!
    private var errorHandler: MockHTTPErrorHandler!
    private(set) var universalHeaders: [String : String]!
    private var httpController: AuthorizingHTTPController<MockAuthorizationProvider>!
}

// MARK: - Setup
extension AuthorizingHTTPControllerTests {

    override func setUp() {
        super.setUp()

        self.httpSession = MockHTTPSession()
        self.errorHandler = MockHTTPErrorHandler()
        self.authorizationProvider = MockAuthorizationProvider()
        self.decoder = JSONDecoder()
        self.universalHeaders = ["headerKey2" : "universalHeaderValue2"]
        self.httpController = AuthorizingHTTPController(
            baseURL: baseURL,
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
extension AuthorizingHTTPControllerTests {

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
        httpController = AuthorizingHTTPController(
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

    // MARK: Error handling
    func testFetchResponse_willThrowErrorReturnedByErrorHandler() async throws {

        let request = MockHTTPRequest { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        errorHandler.result = MockError()
        httpSession.set(response: response, for: request)

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertEqual(errorHandler.recievedResponse?.content, response.content)
            XCTAssertEqual(errorHandler.recievedError as? HTTPStatusCode, .badRequest)
            XCTAssertTrue(error is MockError)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
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
        errorHandler.result = MockError()
        httpSession.set(response: response, for: request)

        httpController = AuthorizingHTTPController(
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

            XCTAssertNil(errorHandler.recievedResponse)
            XCTAssertNil(errorHandler.recievedError)
            XCTAssertEqual(error as? HTTPStatusCode, .badRequest)
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

            XCTAssertNil(errorHandler.recievedError)
            XCTAssertNil(errorHandler.recievedResponse)
            XCTAssertTrue(error is MockHTTPSession.SampleError)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }
}
