import XCTest
@testable import Networking

final class ReauthorizingHTTPControllerTests: XCTestCase {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private let reauthorizationBaseURL = URL(string: "https://reauth.domain.com")!
    private var httpSession: MockHTTPSession!
    private var authorizationProvider: MockHTTPReauthorizationProvider!
    private var delegate: MockReauthorizingHTTPControllerDelegate!
    private var httpController: ReauthorizingHTTPController<MockHTTPReauthorizationProvider>!
}

// MARK: - Setup
extension ReauthorizingHTTPControllerTests {

    override func setUp() {
        super.setUp()

        self.httpSession = MockHTTPSession()
        self.authorizationProvider = MockHTTPReauthorizationProvider()
        self.delegate = MockReauthorizingHTTPControllerDelegate()
        self.httpController = ReauthorizingHTTPController(
            baseURL: baseURL,
            reauthorizationBaseURL: reauthorizationBaseURL,
            session: httpSession,
            dataCoders: .default,
            delegate: delegate,
            authorization: authorizationProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        self.httpSession = nil
        self.authorizationProvider = nil
        self.delegate = nil
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
        XCTAssertEqual(lastReceivedRequest?.headers, request.headers)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
        XCTAssertEqual(lastReceivedBaseURL, baseURL)
    }

    func testFetchResponse_willUseAuthorizationProvider_toAuthorizeRequestBeforeSubmission_whenAuthorizationIsRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: true)
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        var expectedHeaders = request.headers ?? [:]
        expectedHeaders["Authorization"] = "true"

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
        
        XCTAssertEqual(authorizationProvider.authorizedRequest?.pathComponents, request.pathComponents)
    }

    // MARK: - Encoding
    func testFetchResponse_willEncodeBodyUsingRequest_andReturnEncodedBody() async throws {
        
        let expectedResponse = HTTPResponse(
            content: Data(UUID().uuidString.utf8),
            statusCode: .ok,
            headers: [:]
        )

        let bodyData = Data(UUID().uuidString.utf8)

        var encodeData: Data?
        var encodeHeaders: [String : String]?
        var encodeEncoder: DataEncoder?
        let request = MockHTTPRequest(body: bodyData) { body, headers, coders in
            encodeData = body
            encodeHeaders = headers
            encodeEncoder = try coders.requireEncoder(for: .json)
            
            return Data(body.reversed())
        } decode: { data, _, _ in
            data
        }

        httpSession.set(
            response: expectedResponse,
            for: request
        )

        _ = try await httpController.fetchResponse(request)

        var expectedHeaders = request.headers ?? [:]
        expectedHeaders["Authorization"] = "true"

        XCTAssertEqual(encodeData, request.body)
        XCTAssertEqual(encodeHeaders, expectedHeaders)
        XCTAssertIdentical(encodeEncoder as? JSONEncoder, try DataCoders.default.requireEncoder(for: .json) as? JSONEncoder)

        XCTAssertTrue(delegate.controllerPreparingRequest is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
        XCTAssertTrue(delegate.requestPreparedForSubmission is MockHTTPRequest<Data, Data>)
        XCTAssertNotNil(delegate.codersUsedForRequestPreparation)
    }

    // MARK: Decoding
    func testFetchResponse_willDecodeResponseUsingRequest_andReturnDecodedResponse() async throws {

        let responseData = Data(UUID().uuidString.utf8)
        let responseHeaders = ["header1" : "headerValue1"]
        let expectedResponse = HTTPResponse(
            content: responseData,
            statusCode: .ok,
            headers: responseHeaders
        )

        var decodeData: Data?
        var decodeStatusCode: HTTPStatusCode?
        var decodeDecoder: DataDecoder?
        let request = MockHTTPRequest() { body, _, _ in
            body
        } decode: { data, statusCode, coders in
          
            decodeData = data
            decodeStatusCode = statusCode
            decodeDecoder = try coders.requireDecoder(for: .json)
            return data + data
        }

        httpSession.set(
            response: expectedResponse,
            for: request
        )

        let response = try await httpController.fetchResponse(request)

        XCTAssertEqual(decodeData, expectedResponse.content)
        XCTAssertEqual(decodeStatusCode, expectedResponse.statusCode)
        XCTAssertIdentical(decodeDecoder as? JSONDecoder, try DataCoders.default.requireDecoder(for: .json) as? JSONDecoder)

        XCTAssertEqual(response.content, responseData + responseData)
        XCTAssertEqual(response.statusCode, expectedResponse.statusCode)
        XCTAssertEqual(response.headers, expectedResponse.headers)
        
        XCTAssertTrue(delegate.controllerDecodingRequest is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
        XCTAssertEqual(delegate.decodedResponse.map { $0.content + $0.content }, response.content)
        XCTAssertEqual(delegate.decodedResponse?.statusCode, response.statusCode)
        XCTAssertEqual(delegate.decodedResponse?.headers, response.headers)
        XCTAssertTrue(delegate.decodedRequest is MockHTTPRequest<Data, Data>)
        XCTAssertNotNil(delegate.codersUsedForRequestDecoding)
    }
    
    // MARK: Encoding headers
    func testFetchResponse_willAddEncodingHeaders_toRequestBeforeSubmission_whenRequestHasExistingHeaders() async throws {

        let request = MockHTTPRequest(
            headers: ["headerKey2" : "headerValue2"],
            encode: { data, headers, coders in
                headers["encodingKey"] = "encodingValue"
                return data
            },
            decode: { data, statusCode, coders in
                data
            }
        )
        httpSession.setBlankResponse(for: request)
        
        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        let expectedHeaders = [
            "headerKey2" : "headerValue2",
            "encodingKey" : "encodingValue",
            "Authorization" : "true"
        ]
        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func testFetchResponse_willAddEncodingHeaders_toRequestBeforeSubmission_whenRequestHasNoHeaders() async throws {

        let request = MockHTTPRequest(
            headers: nil,
            encode: { data, headers, coders in
                headers["encodingKey"] = "encodingValue"
                return data
            },
            decode: { data, statusCode, coders in
                data
            }
        )
        httpSession.setBlankResponse(for: request)
        
        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        let expectedHeaders = [
            "encodingKey" : "encodingValue",
            "Authorization" : "true"
        ]
        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    // MARK: Access token saving
    func testFetchResponse_willSaveAccessToken_whenPossible() async throws {

        let accessToken = MockAccessToken(value: "accessToken")
        let request = MockHTTPRequest<Data, MockAccessToken> { body, _, _ in
            body
        } decode: { _, _, _ in
            accessToken
        }

        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        XCTAssertEqual(authorizationProvider.handledAuthorizationResponseRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(authorizationProvider.handledAuthorizationResponse?.content, accessToken)
    }

    func testFetchResponse_willSaveRefreshToken_whenPossible() async throws {

        let refreshToken = MockRefreshToken(value: "refreshToken")
        let request = MockHTTPRequest<Data, MockRefreshToken> { body, _, _ in
            body
        } decode: { _, _, _ in
            refreshToken
        }
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        XCTAssertEqual(authorizationProvider.handledReauthorizationResponse?.content, refreshToken)
    }

    // MARK: Reauthorization
    func testFetchResponse_willReauthorizeFailedRequest_whenDelegateSaysTo() async throws {

        let request = MockHTTPRequest { body, _, _ in
            body
        } decode: { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .ok,
            headers: [:]
        )

        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        httpSession.set(response: response, for: request)
        httpSession.setReauthorizationResponse()

        _ = try? await httpController.fetchResponse(request)

        XCTAssertTrue(delegate.controllerAttemptingReauthorization is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
        XCTAssertEqual(delegate.responseTriggeringReauthorization?.content.isEmpty, true)
        XCTAssertEqual(delegate.errorTriggeringReauthorization as? HTTPStatusCode, .unauthorized)
        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertEqual(httpSession.receivedRequests.count, 3)
        XCTAssertEqual(httpSession.receivedRequests.first?.baseURL, baseURL)
        XCTAssertEqual(httpSession.receivedRequests.dropFirst().first?.baseURL, reauthorizationBaseURL)
        XCTAssertEqual(httpSession.receivedRequests.last?.baseURL, baseURL)
    }

    func testFetchResponse_willThrowErrorReturnedByDelegate_whenInitialRequestFails_andDelegateDoesNotAllowReauthorization() async throws {

        let request = MockHTTPRequest { body, _, _ in
            body
        } decode: { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .badRequest,
            headers: [:]
        )
        
        delegate.errorToThrow = MockError()
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = false
        authorizationProvider.shouldMakeReauthorizationRequest = false
        httpSession.set(response: response, for: request)

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertTrue(delegate.controllerAttemptingReauthorization is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
            XCTAssertEqual(delegate.responseTriggeringReauthorization?.content, response.content)
            XCTAssertEqual(delegate.errorTriggeringReauthorization as? HTTPStatusCode, .badRequest)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)

            XCTAssertEqual(delegate.handledErrorResponse?.content, response.content)
            XCTAssertEqual(delegate.handledErrorResponse?.statusCode, .badRequest)
            XCTAssertEqual(delegate.handledError as? HTTPStatusCode, .badRequest)
            XCTAssertTrue(error is MockError)
            XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }

    func testFetchResponse_willThrowErrorReturnedByDelegate_whenRetriedRequestFails() async throws {

        let request = MockHTTPRequest { body, _, _ in
            body
        } decode: { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .unauthorized,
            headers: [:]
        )
        
        delegate.errorToThrow = MockError()
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = true
        httpSession.set(response: response, for: request)
        httpSession.setReauthorizationResponse()

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {
            
            XCTAssertTrue(delegate.controllerAttemptingReauthorization is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
            XCTAssertEqual(delegate.responseTriggeringReauthorization?.content.isEmpty, true)
            XCTAssertEqual(delegate.errorTriggeringReauthorization as? HTTPStatusCode, .unauthorized)
            XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertTrue(error is MockError)
            XCTAssertEqual(httpSession.receivedRequests.count, 3)
            XCTAssertEqual(httpSession.receivedRequests.first?.baseURL, baseURL)
            XCTAssertEqual(httpSession.receivedRequests.dropFirst().first?.baseURL, reauthorizationBaseURL)
            XCTAssertEqual(httpSession.receivedRequests.last?.baseURL, baseURL)
        }
    }

    func testFetchResponse_willThrowErrorReturnedByDelegate_usingOriginalError_whenReauthorizationRequestCannotBeCreated() async throws {

        let request = MockHTTPRequest { body, _, _ in
            body
        } decode: { _, statusCode, _ in
            guard statusCode == .ok else { throw statusCode }
        }
        let response = HTTPResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .ok,
            headers: [:]
        )
        
        delegate.errorToThrow = MockError()
        authorizationProvider.authorizationFailsUntilReauthorizationRequestIsMade = true
        authorizationProvider.shouldMakeReauthorizationRequest = false
        httpSession.set(response: response, for: request)

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {
            
            XCTAssertTrue(delegate.controllerAttemptingReauthorization is ReauthorizingHTTPController<MockHTTPReauthorizationProvider>)
            XCTAssertEqual(delegate.responseTriggeringReauthorization?.content.isEmpty, true)
            XCTAssertEqual(delegate.errorTriggeringReauthorization as? HTTPStatusCode, .unauthorized)
            XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
            XCTAssertTrue(error is MockError)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
            XCTAssertEqual(httpSession.receivedRequests.first?.baseURL, baseURL)
        }
    }

    // MARK: Error reporting
    func testFetchResponse_willReportErrorThrownByHTTPSession_withoutCallingDelegate() async throws {

        let request = MockHTTPRequest()
        httpSession.shouldThrowErrorOnSubmit = true

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertNil(delegate.controllerThrowingError)
            XCTAssertNil(delegate.handledError)
            XCTAssertNil(delegate.handledErrorResponse)

            XCTAssertTrue(error is MockError)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }
}
