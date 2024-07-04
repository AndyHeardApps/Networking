import Foundation
import Testing
@testable import Networking

@Suite(
    "AnyWebSocketRequest",
    .tags(.webSocket)
)
struct AnyWebSocketRequestTests {}

// MARK: - Tests
extension AnyWebSocketRequestTests {
    
    @Test("Memberwise initializer assigns properties and coding correctly")
    func memberwiseInitializerAssignsPropertiesAndCodingCorrectly() throws {

        let request = AnyWebSocketRequest<Data, Data>(
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "headerValue1", "header2" : "headerValue2"],
            queryItems: ["query1" : "queryValue1", "query2" : "queryValue2"],
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in data + data }
        )
        
        #expect(request.pathComponents == ["path1", "path2"])
        #expect(request.headers == ["header1" : "headerValue1", "header2" : "headerValue2"])
        #expect(request.queryItems == ["query1" : "queryValue1", "query2" : "queryValue2"])

        let input = Data(UUID().uuidString.utf8)
        let encodedContent = try request.encode(
            input: input,
            using: .default
        )
        
        #expect(encodedContent == Data(input.reversed()))

        let output = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: output,
            using: .default
        )
        
        #expect(decodedContent == output + output)
    }
        
    @Test("Request initializer assigns properties and coding correctly")
    func requestInitializerAssignsPropertiesAndCodingCorrectly() throws {

        let mockRequest = MockWebSocketRequest(
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in data + data }
        )

        let anyWebSocketRequest = AnyWebSocketRequest(mockRequest)
        
        #expect(anyWebSocketRequest.pathComponents == mockRequest.pathComponents)
        #expect(anyWebSocketRequest.headers == mockRequest.headers)
        #expect(anyWebSocketRequest.queryItems == mockRequest.queryItems)

        let input = Data(UUID().uuidString.utf8)
        let encodedContent = try anyWebSocketRequest.encode(
            input: input,
            using: .default
        )
        
        #expect(encodedContent == Data(input.reversed()))

        let output = Data(UUID().uuidString.utf8)
        let decodedContent = try anyWebSocketRequest.decode(
            data: output,
            using: .default
        )
        
        #expect(decodedContent == output + output)
    }
    
    @Test("Default protocol values")
    func defaultProtocolValues() throws {

        struct BasicRequest: WebSocketRequest {
            typealias Input = [String : Int]
            typealias Output = [String : Int]
            
            let pathComponents: [String]
            let requiresAuthorization = false
        }
        
        let request = BasicRequest(pathComponents: [])
        
        #expect(request.headers == nil)
        #expect(request.queryItems == nil)

        #expect(try request.encode(input: ["key" : 1], using: .default) == Data("{\"key\":1}".utf8))
        #expect(try request.decode(data: Data("{\"key\":1}".utf8), using: .default) == ["key" : 1])
    }
}
