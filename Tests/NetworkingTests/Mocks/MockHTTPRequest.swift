import Foundation
@testable import Networking

struct MockHTTPRequest<Body, Response>: HTTPRequest {

    // MARK: - Properties
    let httpMethod: HTTPMethod
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    let body: Body?
    let requiresAuthorization: Bool
    private let transformClosure: (Data, HTTPStatusCode, DataDecoder) throws -> Response
    
    // MARK: - Initialiser
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Body? = Data(UUID().uuidString.utf8),
        requiresAuthorization: Bool = true,
        transformClosure: @escaping (Data, HTTPStatusCode, DataDecoder) throws -> Response
    ) {
       
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
        self.transformClosure = transformClosure
    }
}

// MARK: - Void initialiser
extension MockHTTPRequest where Response == Void {
    
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Body? = Data(UUID().uuidString.utf8),
        requiresAuthorization: Bool = true
    ) {
       
        self.httpMethod = httpMethod
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
        self.transformClosure = { _, _, _ in () }
    }
}

// MARK: - Transform
extension MockHTTPRequest {
    
    func transform(
        data: Data,
        statusCode: HTTPStatusCode,
        using decoder: DataDecoder
    ) throws -> Response {
        
        try transformClosure(data, statusCode, decoder)
    }
}
