import Foundation
@testable import Networking

struct MockNetworkRequest<ResponseType>: NetworkRequest {

    // MARK: - Properties
    let httpMethod: HTTPMethod
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    let body: UUID?
    let requiresAuthorization: Bool
    private let transformClosure: (Data, HTTPStatusCode, DataDecoder) throws -> ResponseType
    
    // MARK: - Initialiser
    init(
        httpMethod: HTTPMethod = .get,
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        body: UUID? = UUID(),
        requiresAuthorization: Bool = true,
        transformClosure: @escaping (Data, HTTPStatusCode, DataDecoder) throws -> ResponseType
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
        body: UUID? = UUID(),
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
    
    func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> ResponseType {
        
        try transformClosure(data, statusCode, decoder)
    }
}
