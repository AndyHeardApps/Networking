import XCTest
@testable import Networking

final class AnyRequestTests: XCTestCase {}

// MARK: - Mocks
extension AnyRequestTests {
    
    private struct MockRequest: NetworkRequest {
        
        let httpMethod: HTTPMethod = .delete
        let pathComponents: [String] = [UUID().uuidString, UUID().uuidString]
        let headers: [String : String]? = [UUID().uuidString : UUID().uuidString]
        let queryItems: [String : String]? = [UUID().uuidString : UUID().uuidString]
        let body: Data? = UUID().uuidString.data(using: .utf8)
        let requiresAuthorization: Bool = .random()
        
        func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws -> String {
            
            String(data: data, encoding: .utf8)!
        }
    }
}

// MARK: - Tests
extension AnyRequestTests {
    
    func testAnyRequestInitWithRequest_willUseInjectedRequestParameters_andTransform() throws {
        
        let request = MockRequest()
        let anyRequest = AnyRequest(request)
        
        XCTAssertEqual(request.httpMethod, anyRequest.httpMethod)
        XCTAssertEqual(request.pathComponents, anyRequest.pathComponents)
        XCTAssertEqual(request.headers, anyRequest.headers)
        XCTAssertEqual(request.queryItems, anyRequest.queryItems)
        XCTAssertEqual(request.body, anyRequest.body)
        XCTAssertEqual(request.requiresAuthorization, anyRequest.requiresAuthorization)

        let transformString = UUID().uuidString
        let transformData = transformString.data(using: .utf8)!
        
        XCTAssertEqual(try request.transform(data: transformData, statusCode: .ok, using: .init()), transformString)
        XCTAssertEqual(try anyRequest.transform(data: transformData, statusCode: .ok, using: .init()), transformString)
    }
}
