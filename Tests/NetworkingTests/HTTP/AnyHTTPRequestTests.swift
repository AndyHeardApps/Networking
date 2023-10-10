import XCTest
@testable import Networking

final class AnyHTTPRequestTests: XCTestCase {}

// MARK: - Tests
extension AnyHTTPRequestTests {
    
    func testInitWithParameters_willAssignProperties_andCodingCorrectly() throws {
        
        let body = Data(UUID().uuidString.utf8)
        let request = AnyHTTPRequest(
            httpMethod: .connect,
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            body: body,
            requiresAuthorization: true,
            encode: { body, headers, coders in
                Data(body.reversed())
            },
            decode: { data, statusCode, coders in
                data + data
            }
        )
        
        XCTAssertEqual(request.httpMethod, .connect)
        XCTAssertEqual(request.pathComponents, ["path1", "path2"])
        XCTAssertEqual(request.headers, ["header1" : "headerValue1", "header2" : "headerValue2"])
        XCTAssertEqual(request.queryItems, ["query1" : "queryValue1", "query2" : "queryValue2"])
        XCTAssertEqual(request.body, body)
        XCTAssertTrue(request.requiresAuthorization)

        var headers: [String : String] = [:]
        let encodedContent = try request.encode(
            body: body,
            headers: &headers,
            using: .default
        )
        
        XCTAssertEqual(encodedContent, Data(body.reversed()))

        let mockData = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: mockData,
            statusCode: .ok,
            using: .default
        )
        
        XCTAssertEqual(decodedContent, mockData + mockData)
    }
    
    func testInitWithDataBodyParameters_willAssignProperties_andCodingCorrectly() throws {
        
        let body = Data(UUID().uuidString.utf8)
        let request = AnyHTTPRequest(
            httpMethod: .connect,
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            body: body,
            requiresAuthorization: true,
            decode: { data, statusCode, coders in
                data + data
            }
        )
        
        XCTAssertEqual(request.httpMethod, .connect)
        XCTAssertEqual(request.pathComponents, ["path1", "path2"])
        XCTAssertEqual(request.headers, ["header1" : "headerValue1", "header2" : "headerValue2"])
        XCTAssertEqual(request.queryItems, ["query1" : "queryValue1", "query2" : "queryValue2"])
        XCTAssertEqual(request.body, body)
        XCTAssertTrue(request.requiresAuthorization)

        var headers: [String : String] = [:]
        let encodedContent = try request.encode(
            body: body,
            headers: &headers,
            using: .default
        )
        
        XCTAssertEqual(encodedContent, body)

        let mockData = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: mockData,
            statusCode: .ok,
            using: .default
        )
        
        XCTAssertEqual(decodedContent, mockData + mockData)
    }
    
    func testInitWithRequest_willAssignProperties_andCodingCorrectly() throws {
        
        let mockRequest = MockHTTPRequest { body, _, _ in
            Data(body.reversed())
        } decode: { data, _, _ in
            data + data
        }

        let anyHTTPRequest = AnyHTTPRequest(mockRequest)
        
        XCTAssertEqual(anyHTTPRequest.httpMethod, mockRequest.httpMethod)
        XCTAssertEqual(anyHTTPRequest.pathComponents, mockRequest.pathComponents)
        XCTAssertEqual(anyHTTPRequest.headers, mockRequest.headers)
        XCTAssertEqual(anyHTTPRequest.queryItems, mockRequest.queryItems)
        XCTAssertEqual(anyHTTPRequest.body, mockRequest.body)
        XCTAssertEqual(anyHTTPRequest.requiresAuthorization, mockRequest.requiresAuthorization)

        let body = Data(UUID().uuidString.utf8)
        var headers: [String : String] = [:]
        let encodedRequestContent = try mockRequest.encode(body: body, headers: &headers, using: .default)
        let encodedAnyHTTPRequestContent = try anyHTTPRequest.encode(body: body, headers: &headers, using: .default)
        
        XCTAssertEqual(encodedRequestContent, encodedAnyHTTPRequestContent)
        
        let mockData = Data(UUID().uuidString.utf8)
        let decodedRequestContent = try mockRequest.decode(data: mockData, statusCode: .ok, using: .default)
        let decodedAnyHTTPRequestContent = try anyHTTPRequest.decode(data: mockData, statusCode: .ok, using: .default)

        XCTAssertEqual(decodedRequestContent, decodedAnyHTTPRequestContent)
    }
}
