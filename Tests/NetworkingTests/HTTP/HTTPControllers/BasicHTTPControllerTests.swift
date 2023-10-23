import XCTest
@testable import Networking

final class BasicHTTPControllerTests: XCTestCase {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private var httpSession: MockHTTPSession!
    private var delegate: MockHTTPControllerDelegate!
    private var httpController: BasicHTTPController!
}

// MARK: - Setup
extension BasicHTTPControllerTests {

    override func setUp() {
        super.setUp()

        self.httpSession = MockHTTPSession()
        self.delegate = MockHTTPControllerDelegate()
        self.httpController = BasicHTTPController(
            baseURL: baseURL,
            session: httpSession,
            dataCoders: .default,
            delegate: delegate
        )
    }

    override func tearDown() {
        super.tearDown()

        self.httpSession = nil
        self.delegate = nil
        self.httpController = nil
    }
}

// MARK: - Tests
extension BasicHTTPControllerTests {

    // MARK: Request manipulation
    func test_fetchResponse_willSubmitRequest_toHTTPSession_withoutAssertionFailure_whenAuthorizationIsNotRequired() async throws {

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

    func test_fetchResponse_willCauseAssertionFailure_whenAuthorizationIsRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: true)
        httpSession.setBlankResponse(for: request)

        do {
            _ = try await httpController.fetchResponse(request)
        } catch {
            XCTAssertEqual(error as? HTTPStatusCode, .unauthorized)
        }
    }
    
    // MARK: - Encoding
    func test_fetchResponse_willEncodeBodyUsingRequest_andReturnEncodedBody() async throws {
        
        let expectedResponse = HTTPResponse(
            content: Data(UUID().uuidString.utf8),
            statusCode: .ok,
            headers: [:]
        )

        let bodyData = Data(UUID().uuidString.utf8)

        var encodeData: Data?
        var encodeHeaders: [String : String]?
        var encodeEncoder: DataEncoder?
        let request = MockHTTPRequest(
            body: bodyData,
            requiresAuthorization: false
        ) { body, headers, coders in
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

        XCTAssertEqual(encodeData, request.body)
        XCTAssertEqual(encodeHeaders, request.headers)
        XCTAssertIdentical(encodeEncoder as? JSONEncoder, try DataCoders.default.requireEncoder(for: .json) as? JSONEncoder)

        XCTAssertTrue(delegate.controllerPreparingRequest is BasicHTTPController)
        XCTAssertTrue(delegate.requestPreparedForSubmission is MockHTTPRequest<Data, Data>)
        XCTAssertNotNil(delegate.codersUsedForRequestPreparation)
    }

    // MARK: Decoding
    func test_fetchResponse_willDecodeResponseUsingRequest_andReturnDecodedResponse() async throws {

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
        let request = MockHTTPRequest(
            requiresAuthorization: false
        ) { body, _, _ in
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
        
        XCTAssertTrue(delegate.controllerDecodingRequest is BasicHTTPController)
        XCTAssertEqual(delegate.decodedResponse.map { $0.content + $0.content }, response.content)
        XCTAssertEqual(delegate.decodedResponse?.statusCode, response.statusCode)
        XCTAssertEqual(delegate.decodedResponse?.headers, response.headers)
        XCTAssertTrue(delegate.decodedRequest is MockHTTPRequest<Data, Data>)
        XCTAssertNotNil(delegate.codersUsedForRequestDecoding)    }

    // MARK: Encoding headers
    func test_fetchResponse_willAddEncodingHeaders_toRequestBeforeSubmission_whenRequestHasExistingHeaders() async throws {

        let request = MockHTTPRequest(
            headers: ["headerKey2" : "headerValue2"],
            requiresAuthorization: false,
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
            "encodingKey" : "encodingValue"
        ]
        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }
    
    func test_fetchResponse_willAddEncodingHeaders_toRequestBeforeSubmission_whenRequestHasNoHeaders() async throws {

        let request = MockHTTPRequest(
            headers: nil,
            requiresAuthorization: false,
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
            "encodingKey" : "encodingValue"
        ]
        XCTAssertEqual(httpSession.receivedRequests.count, 1)
        XCTAssertEqual(lastReceivedRequest?.httpMethod, request.httpMethod)
        XCTAssertEqual(lastReceivedRequest?.pathComponents, request.pathComponents)
        XCTAssertEqual(lastReceivedRequest?.headers, expectedHeaders)
        XCTAssertEqual(lastReceivedRequest?.queryItems, request.queryItems)
        XCTAssertEqual(lastReceivedRequest?.body as? Data, request.body)
        XCTAssertEqual(lastReceivedRequest?.requiresAuthorization, request.requiresAuthorization)
    }

    // MARK: Error handling
    func test_fetchResponse_willThrowErrorReturnedByDelegate() async throws {

        let request = MockHTTPRequest(
            requiresAuthorization: false
        ) { body, _, _ in
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
        httpSession.set(response: response, for: request)

        do {
            _ = try await httpController.fetchResponse(request)
            XCTFail()
        } catch {

            XCTAssertTrue(delegate.controllerThrowingError is BasicHTTPController)
            XCTAssertEqual(delegate.handledError as? HTTPStatusCode, .badRequest)
            XCTAssertEqual(delegate.handledErrorResponse?.content, response.content)
            XCTAssertEqual(delegate.handledErrorResponse?.statusCode, response.statusCode)
            XCTAssertEqual(delegate.handledErrorResponse?.headers, response.headers)

            XCTAssertTrue(error is MockError)
            XCTAssertEqual(httpSession.receivedRequests.count, 1)
        }
    }

    // MARK: Error reporting
    func test_fetchResponse_willReportErrorThrownByHTTPSession_withoutCallingDelegate() async throws {

        let request = MockHTTPRequest(requiresAuthorization: false)
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
