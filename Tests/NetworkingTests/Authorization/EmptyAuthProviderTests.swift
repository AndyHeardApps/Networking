import XCTest
@testable import Networking

final class EmptyAuthorizationProviderTests: XCTestCase {
    
    // MARK: - Properties
    private var authorizationProvider: EmptyAuthorizationProvider!
}

// MARK: - Setup
extension EmptyAuthorizationProviderTests {
    
    override func setUp() {
        super.setUp()
        
        self.authorizationProvider = EmptyAuthorizationProvider()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.authorizationProvider = nil
    }
}

// MARK: - Tests
extension EmptyAuthorizationProviderTests {
    
    func testMakeReauthorizationRequest_willReturnNil() {
        
        let reauthorizationRequest = authorizationProvider.makeReauthorizationRequest()
        
        XCTAssertNil(reauthorizationRequest)
    }

    func testHandleAuthorizationResponse_doesNothing() {
        
        let request = AnyRequest(
            httpMethod: .get,
            pathComponents: [],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: true,
            transform: { _, _, _ in }
        )
        
        let response = NetworkResponse(
            content: (),
            statusCode: .ok,
            headers: [:]
        )

        authorizationProvider.handle(authorizationResponse: response, from: request)
    }
    
    func testHandleReauthorizationResponse_doesNothing() {
        
        let request = AnyRequest(
            httpMethod: .get,
            pathComponents: [],
            headers: nil,
            queryItems: nil,
            body: nil,
            requiresAuthorization: true,
            transform: { _, _, _ in }
        )
        
        let response = NetworkResponse(
            content: (),
            statusCode: .ok,
            headers: [:]
        )

        authorizationProvider.handle(reauthorizationResponse: response, from: request)
    }
    
    func testAuthorizeRequest_willReturnUnalteredRequest() throws {
        
        let request = AnyRequest(
            httpMethod: .connect,
            pathComponents: ["a", "b"],
            headers: ["a" : "A", "b" : "B"],
            queryItems: ["c" : "C", "d" : "D"],
            body: UUID().uuidString.data(using: .utf8),
            requiresAuthorization: true
        ) { data, statusCode, decoder in
            data
        }
        
        let authorizedRequest = authorizationProvider.authorize(request)
        
        let responseData = UUID().uuidString.data(using: .utf8)!
        let requestTransformedResponse = try request.transform(
            data: responseData,
            statusCode: .ok,
            using: .init()
        )
        let authorizedRequestTransformedResponse = try authorizedRequest.transform(
            data: responseData,
            statusCode: .ok,
            using: .init()
        )
        
        XCTAssertEqual(request.httpMethod, authorizedRequest.httpMethod)
        XCTAssertEqual(request.pathComponents, authorizedRequest.pathComponents)
        XCTAssertEqual(request.headers, authorizedRequest.headers)
        XCTAssertEqual(request.queryItems, authorizedRequest.queryItems)
        XCTAssertEqual(request.body, authorizedRequest.body)
        XCTAssertEqual(request.requiresAuthorization, authorizedRequest.requiresAuthorization)
        XCTAssertEqual(requestTransformedResponse, authorizedRequestTransformedResponse)
    }
}
