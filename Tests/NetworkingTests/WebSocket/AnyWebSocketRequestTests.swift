import XCTest
@testable import Networking

final class AnyWebSocketRequestTests: XCTestCase {}

// MARK: - Tests
extension AnyWebSocketRequestTests {
    
    func test_initWithParameters_willAssignProperties_andCodingCorrectly() throws {
        
        let request = AnyWebSocketRequest<Data, Data>(
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in data + data }
        )
        
        XCTAssertEqual(request.pathComponents, ["path1", "path2"])
        XCTAssertEqual(request.headers, ["header1" : "headerValue1", "header2" : "headerValue2"])
        XCTAssertEqual(request.queryItems, ["query1" : "queryValue1", "query2" : "queryValue2"])

        let input = Data(UUID().uuidString.utf8)
        let encodedContent = try request.encode(
            input: input,
            using: .default
        )
        
        XCTAssertEqual(encodedContent, Data(input.reversed()))

        let output = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: output,
            using: .default
        )
        
        XCTAssertEqual(decodedContent, output + output)
    }
        
    func test_initWithRequest_willAssignProperties_andCodingCorrectly() throws {
        
        let mockRequest = MockWebSocketRequest(
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in data + data }
        )

        let anyWebSocketRequest = AnyWebSocketRequest(mockRequest)
        
        XCTAssertEqual(anyWebSocketRequest.pathComponents, mockRequest.pathComponents)
        XCTAssertEqual(anyWebSocketRequest.headers, mockRequest.headers)
        XCTAssertEqual(anyWebSocketRequest.queryItems, mockRequest.queryItems)

        let input = Data(UUID().uuidString.utf8)
        let encodedContent = try anyWebSocketRequest.encode(
            input: input,
            using: .default
        )
        
        XCTAssertEqual(encodedContent, Data(input.reversed()))

        let output = Data(UUID().uuidString.utf8)
        let decodedContent = try anyWebSocketRequest.decode(
            data: output,
            using: .default
        )
        
        XCTAssertEqual(decodedContent, output + output)
    }
    
    func test_initWithDefaultParameters_willAssignProperties_andCodingCorrectly() throws {
        
        struct BasicRequest: WebSocketRequest {
            typealias Input = [String : Int]
            typealias Output = [String : Int]
            
            let pathComponents: [String]
            let requiresAuthorization = false
        }
        
        let request = BasicRequest(pathComponents: [])
        
        XCTAssertNil(request.headers)
        XCTAssertNil(request.queryItems)

        XCTAssertEqual(try request.encode(input: ["key" : 1], using: .default), Data("{\"key\":1}".utf8))
        XCTAssertEqual(try request.decode(data: Data("{\"key\":1}".utf8), using: .default), ["key" : 1])
    }
}
