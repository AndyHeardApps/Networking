import Foundation

extension URLSession: NetworkSession {
    
    public func submit<Request: NetworkRequest>(request: Request, to baseURL: URL) async throws -> NetworkResponse<Data> {

        let urlRequest = try self.urlRequest(for: request, withBaseURL: baseURL)
        let (data, response) = try await self.data(for: urlRequest)
        
        let httpResponse = response as! HTTPURLResponse
        let statusCode = HTTPStatusCode(rawValue: httpResponse.statusCode) ?? .unknown
        let headers = httpResponse.allHeaderFields.compactMapValues { $0 as? String }

        return .init(
            contents: data,
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
            return "GET"
            
        case .head:
            return "HEAD"
            
        case .post:
            return "POST"
            
        case .put:
            return "PUT"
            
        case .delete:
            return "DELETE"
            
        case .connect:
            return "CONNECT"
            
        case .options:
            return "OPTIONS"
            
        case .trace:
            return "TRACE"
            
        case .patch:
            return "PATCH"
            
        }
    }
}


// MARK: - Errors
extension URLSession {
    
    public enum NetworkSessionError: LocalizedError {
        
        case failedToCreateURLFromComponents
    }
}
