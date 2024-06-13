import Foundation
import Testing
@testable import Networking

@Suite(
    "Authorizing HTTPController",
    .tags(.http)
)
struct AuthorizingHTTPControllerTests {

    // MARK: - Properties
    private let baseURL = URL(string: "https://example.domain.com")!
    private let httpSession: MockHTTPSession
    private let authorizationProvider: MockHTTPAuthorizationProvider
    private let delegate: MockHTTPControllerDelegate
    private let httpController: AuthorizingHTTPController<MockHTTPAuthorizationProvider>

    // MARK: - Initializer
    init() {

        self.httpSession = MockHTTPSession()
        self.authorizationProvider = MockHTTPAuthorizationProvider()
        self.delegate = MockHTTPControllerDelegate()
        self.httpController = AuthorizingHTTPController(
            baseURL: baseURL,
            session: httpSession,
            dataCoders: .default,
            delegate: delegate,
            authorization: authorizationProvider
        )
    }
}

// MARK: - Tests
extension AuthorizingHTTPControllerTests {

    // MARK: Request authorization
    @Test("fetchResponse submits request without authorization when not required")
    func fetchResponseSubmitsRequestWithoutAuthorizationWhenNotRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: false)
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        let lastReceivedRequest = httpSession.receivedRequests.last?.request
        let lastReceivedBaseURL = httpSession.receivedRequests.last?.baseURL

        #expect(httpSession.receivedRequests.count == 1)
        #expect(lastReceivedRequest?.httpMethod == request.httpMethod)
        #expect(lastReceivedRequest?.pathComponents == request.pathComponents)
        #expect(lastReceivedRequest?.headers == request.headers)
        #expect(lastReceivedRequest?.queryItems == request.queryItems)
        #expect(lastReceivedRequest?.body as? Data == request.body)
        #expect(lastReceivedRequest?.requiresAuthorization == request.requiresAuthorization)
        #expect(lastReceivedBaseURL == baseURL)
    }

    @Test("fetchResponse will authorize request when required")
    func fetchResponseWillAuthorizeRequestWhenRequired() async throws {

        let request = MockHTTPRequest(requiresAuthorization: true)
        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        var expectedHeaders = request.headers ?? [:]
        expectedHeaders["Authorization"] = "true"

        let lastReceivedRequest = httpSession.receivedRequests.last?.request

        #expect(httpSession.receivedRequests.count == 1)
        #expect(lastReceivedRequest?.httpMethod == request.httpMethod)
        #expect(lastReceivedRequest?.pathComponents == request.pathComponents)
        #expect(lastReceivedRequest?.headers == expectedHeaders)
        #expect(lastReceivedRequest?.queryItems == request.queryItems)
        #expect(lastReceivedRequest?.body as? Data == request.body)
        #expect(lastReceivedRequest?.requiresAuthorization == request.requiresAuthorization)
        
        #expect(authorizationProvider.authorizedRequest?.pathComponents == request.pathComponents)
    }
    
    // MARK: - Encoding
    @Test("fetchResponse will encode body using request")
    func fetchResponseWillEncodeBodyUsingRequest() async throws {

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

        #expect(encodeData == request.body)
        #expect(encodeHeaders == expectedHeaders)
        #expect(try encodeEncoder as? JSONEncoder === DataCoders.default.requireEncoder(for: .json) as? JSONEncoder)

        #expect(delegate.controllerPreparingRequest is AuthorizingHTTPController<MockHTTPAuthorizationProvider>)
        #expect(delegate.requestPreparedForSubmission is MockHTTPRequest<Data, Data>)
        #expect(delegate.codersUsedForRequestPreparation != nil)
    }
    
    // MARK: Decoding
    @Test("fetchResponse will decode body using request")
    func fetchResponseWillDecodeBodyUsingRequest() async throws {

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

        #expect(decodeData == expectedResponse.content)
        #expect(decodeStatusCode == expectedResponse.statusCode)
        #expect(try decodeDecoder as? JSONDecoder === DataCoders.default.requireDecoder(for: .json) as? JSONDecoder)

        #expect(response.content == responseData + responseData)
        #expect(response.statusCode == expectedResponse.statusCode)
        #expect(response.headers == expectedResponse.headers)
        
        #expect(delegate.controllerDecodingRequest is AuthorizingHTTPController<MockHTTPAuthorizationProvider>)
        #expect(delegate.decodedResponse.map { $0.content + $0.content } == response.content)
        #expect(delegate.decodedResponse?.statusCode == response.statusCode)
        #expect(delegate.decodedResponse?.headers == response.headers)
        #expect(delegate.decodedRequest is MockHTTPRequest<Data, Data>)
        #expect(delegate.codersUsedForRequestDecoding != nil)
    }

    // MARK: Encoding headers
    @Test("fetchResponse adds encoding headers to existing request headers")
    func fetchResponseAddsEncodingHeadersToExistingRequestHeaders() async throws {

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
        #expect(httpSession.receivedRequests.count == 1)
        #expect(lastReceivedRequest?.httpMethod == request.httpMethod)
        #expect(lastReceivedRequest?.pathComponents == request.pathComponents)
        #expect(lastReceivedRequest?.headers == expectedHeaders)
        #expect(lastReceivedRequest?.queryItems == request.queryItems)
        #expect(lastReceivedRequest?.body as? Data == request.body)
        #expect(lastReceivedRequest?.requiresAuthorization == request.requiresAuthorization)
    }
    
    @Test("fetchResponse adds encoding headers to nil request headers")
    func fetchResponseAddsEncodingHeadersToNilRequestHeaders() async throws {

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
        #expect(httpSession.receivedRequests.count == 1)
        #expect(lastReceivedRequest?.httpMethod == request.httpMethod)
        #expect(lastReceivedRequest?.pathComponents == request.pathComponents)
        #expect(lastReceivedRequest?.headers == expectedHeaders)
        #expect(lastReceivedRequest?.queryItems == request.queryItems)
        #expect(lastReceivedRequest?.body as? Data == request.body)
        #expect(lastReceivedRequest?.requiresAuthorization == request.requiresAuthorization)
    }
    
    // MARK: Access token saving
    @Test("fetchResponse saves access token")
    func fetchResponseSavesAccessToken() async throws {

        let accessToken = MockAccessToken(value: "accessToken")
        let request = MockHTTPRequest<Data, MockAccessToken> { body, _, _ in
            body
        } decode: { _, _, _ in
            accessToken
        }

        httpSession.setBlankResponse(for: request)

        _ = try await httpController.fetchResponse(request)

        #expect(authorizationProvider.handledAuthorizationResponseRequest?.pathComponents == request.pathComponents)
        #expect(authorizationProvider.handledAuthorizationResponse?.content == accessToken)
    }
    
    // MARK: Error handling
    @Test("fetchResponse throws errors returned by delegate")
    func fetchResponseThrowsErrorsReturnedByDelegate() async throws {

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
        httpSession.set(response: response, for: request)

        try await #require(throws: MockError.self) {
            _ = try await httpController.fetchResponse(request)
        }

        #expect(delegate.controllerThrowingError is AuthorizingHTTPController<MockHTTPAuthorizationProvider>)
        #expect(delegate.handledError as? HTTPStatusCode == .badRequest)
        #expect(delegate.handledErrorResponse?.content == response.content)
        #expect(delegate.handledErrorResponse?.statusCode == response.statusCode)
        #expect(delegate.handledErrorResponse?.headers == response.headers)

        #expect(httpSession.receivedRequests.count == 1)
    }

    // MARK: Error reporting
    @Test("fetchResponse throws errors from HTTPSession without calling delegate")
    func fetchResponseThrowsErrorsFromHTTPSessionWithoutCallingDelegate() async throws {

        let request = MockHTTPRequest()
        httpSession.shouldThrowErrorOnSubmit = true

        try await #require(throws: MockError.self) {
            _ = try await httpController.fetchResponse(request)
        }

        #expect(delegate.controllerThrowingError == nil)
        #expect(delegate.handledError == nil)
        #expect(delegate.handledErrorResponse == nil)

        #expect(httpSession.receivedRequests.count == 1)
    }
}
