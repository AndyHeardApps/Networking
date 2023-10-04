import XCTest
@testable import Networking

final class AnyNetworkRequestTests: XCTestCase {}

// MARK: - Tests
extension AnyNetworkRequestTests {
    
    func testInitWithParameters_willAssignProperties_andTransformCorrectly() throws {
        
        let body = UUID().uuidString.data(using: .utf8)
        let request = AnyNetworkRequest(
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
        let anyNetworkRequest = AnyNetworkRequest(mockRequest)
        
        XCTAssertEqual(anyNetworkRequest.httpMethod, mockRequest.httpMethod)
        XCTAssertEqual(anyNetworkRequest.pathComponents, mockRequest.pathComponents)
        XCTAssertEqual(anyNetworkRequest.headers, mockRequest.headers)
        XCTAssertEqual(anyNetworkRequest.queryItems, mockRequest.queryItems)
        XCTAssertEqual(anyNetworkRequest.body, mockRequest.body)
        XCTAssertEqual(anyNetworkRequest.requiresAuthorization, mockRequest.requiresAuthorization)

        let mockData = UUID().uuidString.data(using: .utf8)!
        let transformedRequestContent = try mockRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())
        let transformedAnyNetworkRequestContent = try anyNetworkRequest.transform(data: mockData, statusCode: .ok, using: JSONDecoder())

        XCTAssertEqual(transformedRequestContent, transformedAnyNetworkRequestContent)
    }
}
