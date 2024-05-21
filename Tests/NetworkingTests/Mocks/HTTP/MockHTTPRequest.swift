import Foundation
@testable import Networking

struct MockHTTPRequest<Body: Sendable, Response: Sendable>: HTTPRequest, @unchecked Sendable {

    // MARK: - Properties
    let httpMethod: HTTPMethod
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    let body: Body
    let requiresAuthorization: Bool
    private let _encode: (Body, inout [String : String], DataCoders) throws -> Data
    private let _decode: (Data, HTTPStatusCode, DataCoders) throws -> Response

    // MARK: - Initialiser
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Body = Data(UUID().uuidString.utf8),
        requiresAuthorization: Bool = true,
        encode: @escaping (Body, inout [String : String], DataCoders) throws -> Data,
        decode: @escaping (Data, HTTPStatusCode, DataCoders) throws -> Response
    ) {
       
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
        self._encode = encode
        self._decode = decode
    }
}

// MARK: - Void initialisers
extension MockHTTPRequest
where Response == Void,
      Body == Data
{
    
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Data = Data(UUID().uuidString.utf8),
        requiresAuthorization: Bool = true
    ) {
       
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
        self._encode = { body, _, _ in body }
        self._decode = { _, _, _ in () }
    }
}

// MARK: - Coding
extension MockHTTPRequest {

    func encode(body: Body, headers: inout [String : String], using coders: DataCoders) throws -> Data {
        
        try _encode(body, &headers, coders)
    }
    
    func decode(data: Data, statusCode: HTTPStatusCode, using coders: DataCoders) throws -> Response {
        
        try _decode(data, statusCode, coders)
    }
}
