import Foundation

extension URLSession: NetworkSession {
    
    public func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data> {

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
    
    private func urlRequest<Request: NetworkRequest>(for request: Request, withBaseURL baseURL: URL) throws -> URLRequest {
        
        var urlComponents = URLComponents()
        urlComponents.path = request.pathComponents.joined(separator: "/")
        urlComponents.queryItems = request.queryItems?.map(URLQueryItem.init)
        
        guard let url = urlComponents.url(relativeTo: baseURL) else {
            throw NetworkSessionError.failedToCreateURLFromComponents
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.asString
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body
        
        return urlRequest
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
