import XCTest
@testable import Networking

final class AnyRequestTests: XCTestCase {}

// MARK: - Tests
extension AnyRequestTests {
    
    func testInitWithParameters_willAssignProperties_andTransformCorrectly() throws {
        
        let body = UUID().uuidString.data(using: .utf8)
        let request = AnyRequest(
            httpMethod: .connect,
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            body: body,
            requiresAuthorization: true
        ) { data, _, _ in
            data + data
        }
        
        XCTAssertEqual(request.httpMethod, .connect)
        XCTAssertEqual(request.pathComponents, ["path1", "path2"])
        XCTAssertEqual(request.headers, ["header1" : "headerValue1", "header2" : "headerValue2"])
        XCTAssertEqual(request.queryItems, ["query1" : "queryValue1", "query2" : "queryValue2"])
        XCTAssertEqual(request.body, body)
        XCTAssertTrue(request.requiresAuthorization)

        let mockData = UUID().uuidString.data(using: .utf8)!
        let transformedContent = try request.transform(data: mockData, statusCode: .ok, using: JSONDecoder())
        
        XCTAssertEqual(transformedContent, mockData + mockData)
    }
    
    func testInitWithRequest_willAssignProperties_andTransformCorrectly() throws {
        
        let mockRequest = MockNetworkRequest { data, _, _ in
            data + data
        }
        let anyRequest = AnyRequest(mockRequest)
        
        XCTAssertEqual(anyRequest.httpMethod, mockRequest.httpMethod)
        XCTAssertEqual(anyRequest.pathComponents, mockRequest.pathComponents)
        XCTAssertEqual(anyRequest.headers, mockRequest.headers)
        XCTAssertEqual(anyRequest.queryItems, mockRequest.queryItems)
        XCTAssertEqual(anyRequest.body, mockRequest.body)
        XCTAssertEqual(anyRequest.requiresAuthorization, mockRequest.requiresAuthorization)

        let mockData = UUID().uuidString.data(using: .utf8)!
        let transformedRequestContent = try mockRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())
        let transformedAnyRequestContent = try anyRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())

        XCTAssertEqual(transformedRequestContent, transformedAnyRequestContent)
    }
}
