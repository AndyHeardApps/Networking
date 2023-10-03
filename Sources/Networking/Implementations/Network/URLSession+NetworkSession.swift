import Foundation

extension URLSession: NetworkSession {
    
    /// The `DataEncoder` used to encode the bodies of all `NetworkRequest`s submitted to the `URLSession`.
    public static var bodyEncoder: any DataEncoder = JSONEncoder()
    
    public func submit(
        request:  some NetworkRequest,
        to baseURL: URL
    ) async throws -> NetworkResponse<Data> {

        let urlRequest = try self.urlRequest(for: request, withBaseURL: baseURL)
        let (data, response) = try await self.data(for: urlRequest)
        
        let httpResponse = response as! HTTPURLResponse
        let statusCode = HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .unknown
        let headers = httpResponse.allHeaderFields.compactMapValues { $0 as? String }

        return .init(
            content: data,
            statusCode: statusCode,
            headers: headers
        )
    }
}

// MARK: - URL request
extension URLSession {
    
    private func urlRequest(
        httpMethod: HTTPMethod,
        pathComponents: [String],
        headers: [String : String]?,
        queryItems: [String : String]?,
        body: (some Encodable)?,
        baseURL: URL
    ) throws -> URLRequest {
        
        var urlComponents = URLComponents()
        urlComponents.path = pathComponents.joined(separator: "/")
        urlComponents.queryItems = queryItems?.map(URLQueryItem.init)
        
        guard let url = urlComponents.url(relativeTo: baseURL) else {
            throw NetworkSessionError.failedToCreateURLFromComponents
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.asString
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpBody = try body.map(Self.bodyEncoder.encode)
        
        return urlRequest
    }
    
    private func urlRequest<Request: NetworkRequest>(
        for request: Request,
        withBaseURL baseURL: URL
    ) throws -> URLRequest {
        
        try urlRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: request.headers,
            queryItems: request.queryItems,
            body: request.body,
            baseURL: baseURL
        )
    }
    
    private func urlRequest<Request: NetworkWebSocketRequest>(
        for request: Request,
        withBaseURL baseURL: URL
    ) throws -> URLRequest {
        
        try urlRequest(
            httpMethod: .get,
            pathComponents: request.pathComponents,
            headers: request.headers,
            queryItems: request.queryItems,
            body: Never?.none,
            baseURL: baseURL
        )
    }
}

// MARK: - HTTP method
extension HTTPMethod {
    
    fileprivate var asString: String {
        
        switch self {
        case .get:
            "GET"
            
        case .head:
            "HEAD"
            
        case .post:
            "POST"
            
        case .put:
            "PUT"
            
        case .delete:
            "DELETE"
            
        case .connect:
            "CONNECT"
            
        case .options:
            "OPTIONS"
            
        case .trace:
            "TRACE"
            
        case .patch:
            "PATCH"
            
        }
    }
}

// MARK: - Errors
extension URLSession {
    
    enum NetworkSessionError: LocalizedError {
        
        case failedToCreateURLFromComponents
    }
}
