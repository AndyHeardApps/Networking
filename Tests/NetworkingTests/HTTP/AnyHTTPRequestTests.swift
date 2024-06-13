import Foundation
import Testing
@testable import Networking

@Suite(
    "AnyHTTPRequest",
    .tags(.http)
)
struct AnyHTTPRequestTests {}

// MARK: - Tests
extension AnyHTTPRequestTests {
    
    @Test("Memberwise initializer assigns properties and coding correctly")
    func memberwiseInitializerAssignsPropertiesAndCodingCorrectly() throws {

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
        
        #expect(request.httpMethod == .connect)
        #expect(request.pathComponents == ["path1", "path2"])
        #expect(request.headers == ["header1" : "headerValue1", "header2" : "headerValue2"])
        #expect(request.queryItems == ["query1" : "queryValue1", "query2" : "queryValue2"])
        #expect(request.body == body)
        #expect(request.requiresAuthorization)

        var headers: [String : String] = [:]
        let encodedContent = try request.encode(
            body: body,
            headers: &headers,
            using: .default
        )
        
        #expect(encodedContent == Data(body.reversed()))

        let mockData = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: mockData,
            statusCode: .ok,
            using: .default
        )
        
        #expect(decodedContent == mockData + mockData)
    }
    
    @Test("Memberwise initialize with Data body assigns properties and coding correctly")
    func memberwiseInitializeWithDataBodyAssignsPropertiesAndCodingCorrectly() throws {

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
        
        #expect(request.httpMethod == .connect)
        #expect(request.pathComponents == ["path1", "path2"])
        #expect(request.headers == ["header1" : "headerValue1", "header2" : "headerValue2"])
        #expect(request.queryItems == ["query1" : "queryValue1", "query2" : "queryValue2"])
        #expect(request.body == body)
        #expect(request.requiresAuthorization)

        var headers: [String : String] = [:]
        let encodedContent = try request.encode(
            body: body,
            headers: &headers,
            using: .default
        )
        
        #expect(encodedContent == body)

        let mockData = Data(UUID().uuidString.utf8)
        let decodedContent = try request.decode(
            data: mockData,
            statusCode: .ok,
            using: .default
        )
        
        #expect(decodedContent == mockData + mockData)
    }
    
    @Test("Request initializer assigns properties and coding correctly")
    func requestInitializerAssignsPropertiesAndCodingCorrectly() throws {

        let mockRequest = MockHTTPRequest { body, _, _ in
            Data(body.reversed())
        } decode: { data, _, _ in
            data + data
        }

        let anyHTTPRequest = AnyHTTPRequest(mockRequest)
        
        #expect(anyHTTPRequest.httpMethod == mockRequest.httpMethod)
        #expect(anyHTTPRequest.pathComponents == mockRequest.pathComponents)
        #expect(anyHTTPRequest.headers == mockRequest.headers)
        #expect(anyHTTPRequest.queryItems == mockRequest.queryItems)
        #expect(anyHTTPRequest.body == mockRequest.body)
        #expect(anyHTTPRequest.requiresAuthorization == mockRequest.requiresAuthorization)

        let body = Data(UUID().uuidString.utf8)
        var headers: [String : String] = [:]
        let encodedRequestContent = try mockRequest.encode(body: body, headers: &headers, using: .default)
        let encodedAnyHTTPRequestContent = try anyHTTPRequest.encode(body: body, headers: &headers, using: .default)
        
        #expect(encodedRequestContent == encodedAnyHTTPRequestContent)
        
        let mockData = Data(UUID().uuidString.utf8)
        let decodedRequestContent = try mockRequest.decode(data: mockData, statusCode: .ok, using: .default)
        let decodedAnyHTTPRequestContent = try anyHTTPRequest.decode(data: mockData, statusCode: .ok, using: .default)

        #expect(decodedRequestContent == decodedAnyHTTPRequestContent)
    }

    @Test("Request initializer with Never body assigns properties and coding correctly")
    func requestInitializerWithNeverBodyAssignsPropertiesAndCodingCorrectly() throws {

        struct NeverRequest: HTTPRequest {

            let httpMethod: HTTPMethod
            let pathComponents: [String]

            func decode(
                data: Data,
                statusCode: Networking.HTTPStatusCode,
                using coders: Networking.DataCoders
            ) throws {}
        }

        let neverRequest = NeverRequest(
            httpMethod: .get,
            pathComponents: []
        )
        let request = AnyHTTPRequest(neverRequest)

        #expect(request.headers == nil)
        #expect(request.queryItems == nil)
        #expect(request.requiresAuthorization == false)
    }

    @Test("Default protocol values")
    func defaultProtocolValues() throws {

        struct BasicRequest: HTTPRequest {
            
            let httpMethod: HTTPMethod
            let pathComponents: [String]
            let body: [String : Int]?
            
            func decode(
                data: Data,
                statusCode: Networking.HTTPStatusCode,
                using coders: Networking.DataCoders
            ) throws {}
        }
        
        let request = BasicRequest(
            httpMethod: .get,
            pathComponents: [],
            body: ["key" : 1]
        )
        
        #expect(request.headers == nil)
        #expect(request.queryItems == nil)
        #expect(request.requiresAuthorization == false)
        var headers = request.headers ?? [:]
        let encodedBody = try request.encode(
            body: request.body!,
            headers: &headers,
            using: .default
        )
        #expect(encodedBody == Data("{\"key\":1}".utf8))
        #expect(headers == ["Content-Type" : "application/json"])
    }
}
