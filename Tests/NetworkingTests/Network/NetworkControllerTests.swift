import XCTest
@testable import Networking

final class NetworkControllerTests: XCTestCase {
    
    // MARK: - Properties
    private var authorizationProvider: MockAuthorizationProvider!
    private var networkSession: MockNetworkSession!
    private var networkController: NetworkController<MockAuthorizationProvider>!
}

// MARK: - Setup
extension NetworkControllerTests {
    
    override func setUp() {
        super.setUp()
        
        authorizationProvider = MockAuthorizationProvider()
        networkSession = MockNetworkSession()
        networkController = NetworkController(
            baseURL: URL(string: "https://www.test.com")!,
            session: networkSession,
            authorization: authorizationProvider
        )
    }
    
    override func tearDown() {
        super.tearDown()
        
        networkController = nil
    }
}

// MARK: - Mocks
extension NetworkControllerTests {
    
    private final class MockAuthorizationProvider: AuthorizationProvider {
        
        typealias AuthorizationRequest = AnyRequest<Int>
        typealias ReauthorizationRequest = AnyRequest<Double>
        
        var reauthorizationRequest: AnyRequest<Double>?
        private(set) var makeReauthorizationRequestWasCalled = false
        private(set) var handleAuthorizationResponseWasCalled = false
        private(set) var handleReauthorizationResponseWasCalled = false
        private(set) var authorizeRequestWasCalled = false

        func makeReauthorizationRequest() -> AnyRequest<Double>? {
            
            makeReauthorizationRequestWasCalled = true
            return reauthorizationRequest
        }
     
        func handle(authorizationResponse: NetworkResponse<Int>) {
            
            handleAuthorizationResponseWasCalled = true
        }
        
        func handle(reauthorizationResponse: NetworkResponse<Double>) {
            
            handleReauthorizationResponseWasCalled = true
        }
        
        func authorize<Request: NetworkRequest>(_ request: Request) -> AnyRequest<Request.ResponseType> {
            
            authorizeRequestWasCalled = true
            
            var headers = request.headers ?? [:]
            headers["TestAuthorization"] = "testToken"
            let authorizedRequest = AnyRequest(
                httpMethod: request.httpMethod,
                pathComponents: request.pathComponents,
                headers: headers,
                queryItems: request.queryItems,
                body: request.body,
                requiresAuthorization: request.requiresAuthorization,
                transform: request.transform
            )
            
            return authorizedRequest
        }
    }
    
    private final class MockNetworkSession: NetworkSession {
        
        var responses: [Result<NetworkResponse<Data>, Error>] = []
        private(set) var submittedBaseURL: URL?
        private(set) var submittedRequests: [EquatableNetworkRequest] = []
        
        func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data> {
            
            submittedBaseURL = baseURL
            submittedRequests.append(EquatableNetworkRequest(request))
            
            return try responses.removeFirst().get()
        }
    }
    
    private struct EquatableNetworkRequest: NetworkRequest, Equatable {
        
        let httpMethod: HTTPMethod
        let pathComponents: [String]
        let headers: [String : String]?
        let queryItems: [String : String]?
        let body: Data?
        let requiresAuthorization: Bool
        
        init<Request: NetworkRequest>(_ request: Request) {
            
            self.httpMethod = request.httpMethod
            self.pathComponents = request.pathComponents
            self.headers = request.headers
            self.queryItems = request.queryItems
            self.body = request.body
            self.requiresAuthorization = request.requiresAuthorization
        }
        
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws {}
    }
}

// MARK: - Mock data
extension NetworkControllerTests {
    
    private func standardRequest(requiresAuthorization: Bool) -> AnyRequest<Data> {
        
        AnyRequest<Data>(
            httpMethod: .get,
            pathComponents: [],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: requiresAuthorization,
            transform: { data, _, _ in data }
        )
    }
    
    private var standardRequestResponse: NetworkResponse<Data> {
        
        NetworkResponse(
            content: UUID().uuidString.data(using: .utf8)!,
            statusCode: .ok,
            headers: [UUID().uuidString : UUID().uuidString]
        )
    }
    
    private func authorizedStandardRequest(request: AnyRequest<Data>) -> AnyRequest<Data> {
       
        var headers = request.headers ?? [:]
        headers["TestAuthorization"] = "testToken"
        
        return AnyRequest<Data>(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            transform: request.transform
        )
    }
}

// MARK: - Tests
extension NetworkControllerTests {
    
    func testFetchResponse_willReturnResponse_forStandardRequest_withoutRequestAuthorization_andWithoutReauthorization() async throws {
        
        let request = standardRequest(requiresAuthorization: false)
        let response = standardRequestResponse
        let expectedSubmittedRequests = [EquatableNetworkRequest(request)]
        networkSession.responses = [.success(response)]
        
        let networkResponse = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(networkResponse, response)
        
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchResponse_willReturnResponse_forStandardRequest_withRequestAuthorization_andWithoutReauthorization() async throws {
        
        let request = standardRequest(requiresAuthorization: true)
        let response = standardRequestResponse
        
        let expectedSubmittedRequests = [EquatableNetworkRequest(authorizedStandardRequest(request: request))]
        networkSession.responses = [.success(response)]
        
        let networkResponse = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(networkResponse, response)
        
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertTrue(authorizationProvider.authorizeRequestWasCalled)
    }

    func testFetchResponse_willReturnResponse_forStandardRequest_withRequestAuthorization_andWithReauthorization() async throws {
        
        let request = standardRequest(requiresAuthorization: true)
        let response = standardRequestResponse
        
        let reauthorizationRequest = AnyRequest<Double>(
            httpMethod: .get,
            pathComponents: [],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: false,
            transform: { _, _, _ in 1 }
        )
        let reauthorizationResponse = NetworkResponse(
            content: Data(),
            statusCode: .ok,
            headers: [:]
        )
        let expectedSubmittedRequests = [
            EquatableNetworkRequest(authorizedStandardRequest(request: request)),
            EquatableNetworkRequest(reauthorizationRequest),
            EquatableNetworkRequest(authorizedStandardRequest(request: request))
        ]
        authorizationProvider.reauthorizationRequest = reauthorizationRequest
        networkSession.responses = [
            .failure(HTTPStatusCode.unauthorized),
            .success(reauthorizationResponse),
            .success(response)
        ]
        
        let networkResponse = try await networkController.fetchResponse(request)
        
        XCTAssertEqual(networkResponse, response)
        
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertTrue(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertTrue(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchResponse_willThrowUnauthorizedError_whenReauthorizationIsNotAvailable() async throws {
        
        let request = standardRequest(requiresAuthorization: true)
        
        let expectedSubmittedRequests = [EquatableNetworkRequest(authorizedStandardRequest(request: request))]
        networkSession.responses = [.failure(HTTPStatusCode.unauthorized)]
        
        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? HTTPStatusCode, .unauthorized)
        }
                
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertTrue(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertTrue(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchResponse_willThrowError_whenNonRecoverableErrorIsRecieved() async throws {
        
        let request = standardRequest(requiresAuthorization: true)
        
        let expectedSubmittedRequests = [EquatableNetworkRequest(authorizedStandardRequest(request: request))]
        networkSession.responses = [.failure(HTTPStatusCode.internalServerError)]
        
        do {
            _ = try await networkController.fetchResponse(request)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? HTTPStatusCode, .internalServerError)
        }
                
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertTrue(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchResponse_willForwardAuthorizationRequestResponse_toAuthorizationProvider() async throws {
        
        let request = AnyRequest<Int>(
            httpMethod: .get,
            pathComponents: [],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: false,
            transform: { _, _, _ in 1 }
        )
        let response = NetworkResponse(
            content: Data(),
            statusCode: .ok,
            headers: [:]
        )
        
        let expectedSubmittedRequests = [EquatableNetworkRequest(request)]
        networkSession.responses = [.success(response)]
        
        _ = try await networkController.fetchResponse(request)
                
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertTrue(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchContent_willReturnResponse_forStandardRequest_withoutRequestAuthorization_andWithoutReauthorization() async throws {

        let request = standardRequest(requiresAuthorization: false)
        let response = standardRequestResponse
        let expectedSubmittedRequests = [EquatableNetworkRequest(request)]
        networkSession.responses = [.success(response)]
        
        let networkResponse = try await networkController.fetchContent(request)
        
        XCTAssertEqual(networkResponse, response.content)
        
        XCTAssertEqual(networkSession.submittedBaseURL, networkController.baseURL)
        XCTAssertEqual(networkSession.submittedRequests, expectedSubmittedRequests)

        XCTAssertFalse(authorizationProvider.makeReauthorizationRequestWasCalled)
        XCTAssertFalse(authorizationProvider.handleAuthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.handleReauthorizationResponseWasCalled)
        XCTAssertFalse(authorizationProvider.authorizeRequestWasCalled)
    }
    
    func testFetchContent_willAddUniversalHeaders_toRequest() async throws {
        
        let request = standardRequest(requiresAuthorization: false)
        networkController.universalHeaders = ["UniversalHeader" : "Value"]
        let response = standardRequestResponse
        networkSession.responses = [.success(response)]

        _ = try await networkController.fetchContent(request)

        XCTAssertEqual(networkSession.submittedRequests.first?.headers, networkController.universalHeaders)
    }
}

// MARK: - Extensions
extension NetworkResponse: Equatable where Content: Equatable {
    
    public static func == (lhs: NetworkResponse, rhs: NetworkResponse) -> Bool {
        
        lhs.content == rhs.content &&
        lhs.statusCode == rhs.statusCode &&
        lhs.headers == rhs.headers
    }
}
