import Foundation
@testable import Networking

struct MockNetworkRequest<ResponseType>: NetworkRequest {

    // MARK: - Properties
    let httpMethod: HTTPMethod
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    let body: Data?
    let requiresAuthorization: Bool
    private let transformClosure: (Data, HTTPStatusCode, JSONDecoder) throws -> ResponseType
    
    // MARK: - Initialiser
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Data? = UUID().uuidString.data(using: .utf8),
        requiresAuthorization: Bool = true,
        transformClosure: @escaping (Data, HTTPStatusCode, JSONDecoder) throws -> ResponseType
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
extension MockNetworkRequest where ResponseType == Void {
    
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: Data? = UUID().uuidString.data(using: .utf8),
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
extension MockNetworkRequest {
    
    func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws -> ResponseType {
        
        try transformClosure(data, statusCode, decoder)
    }
}
