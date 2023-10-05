import XCTest
@testable import Networking

final class AnyHTTPRequestTests: XCTestCase {}

// MARK: - Tests
extension AnyHTTPRequestTests {
    
    func testInitWithParameters_willAssignProperties_andTransformCorrectly() throws {
        
        let body = Data(UUID().uuidString.utf8)
        let request = AnyHTTPRequest(
            httpMethod: .connect,
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            body: .data(body),
            requiresAuthorization: true
        ) { data, _, _ in
            data + data
        }
        
        XCTAssertEqual(request.httpMethod, .connect)
        XCTAssertEqual(request.pathComponents, ["path1", "path2"])
        XCTAssertEqual(request.headers, ["header1" : "headerValue1", "header2" : "headerValue2"])
        XCTAssertEqual(request.queryItems, ["query1" : "queryValue1", "query2" : "queryValue2"])
        XCTAssertEqual(request.body, .data(body))
        XCTAssertTrue(request.requiresAuthorization)

        let mockData = UUID().uuidString.data(using: .utf8)!
        let transformedContent = try request.transform(data: mockData, statusCode: .ok, using: JSONDecoder())
        
        XCTAssertEqual(transformedContent, mockData + mockData)
    }
    
    func testInitWithRequest_willAssignProperties_andTransformCorrectly() throws {
        
        let mockRequest = MockHTTPRequest { data, _, _ in
            data + data
        }
        let anyHTTPRequest = AnyHTTPRequest(mockRequest)
        
        XCTAssertEqual(anyHTTPRequest.httpMethod, mockRequest.httpMethod)
        XCTAssertEqual(anyHTTPRequest.pathComponents, mockRequest.pathComponents)
        XCTAssertEqual(anyHTTPRequest.headers, mockRequest.headers)
        XCTAssertEqual(anyHTTPRequest.queryItems, mockRequest.queryItems)
        XCTAssertEqual(anyHTTPRequest.body, mockRequest.body)
        XCTAssertEqual(anyHTTPRequest.requiresAuthorization, mockRequest.requiresAuthorization)

        let mockData = UUID().uuidString.data(using: .utf8)!
        let transformedRequestContent = try mockRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())
        let transformedAnyHTTPRequestContent = try anyHTTPRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())

        XCTAssertEqual(transformedRequestContent, transformedAnyHTTPRequestContent)
    }
}
