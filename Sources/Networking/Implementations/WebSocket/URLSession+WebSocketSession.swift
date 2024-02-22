#if os(iOS) || os(macOS)
import Foundation

extension URLSession: WebSocketSession {
    
    public func createInterface(
        to request: some WebSocketRequest,
        with baseURL: URL
    ) throws -> WebSocketInterface {
        
        let urlRequest = try urlRequest(
            for: request,
            withBaseURL: baseURL
        )
        
        let task = webSocketTask(with: urlRequest)
        
        return task
    }
}

// MARK: - URL request
extension URLSession {
    
    private func urlRequest(
        for request: some WebSocketRequest,
        withBaseURL baseURL: URL
    ) throws -> URLRequest {
        
        var urlComponents = URLComponents()
        urlComponents.path = request.pathComponents.joined(separator: "/")
        urlComponents.queryItems = request.queryItems?.map(URLQueryItem.init)
        
        guard let url = urlComponents.url(relativeTo: baseURL) else {
            throw WebSocketSessionError.failedToCreateURLFromComponents
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.allHTTPHeaderFields = request.headers
                
        return urlRequest
    }
}

// MARK: - Errors
extension URLSession {
    
    enum WebSocketSessionError: LocalizedError {
        
        case failedToCreateURLFromComponents
    }
}
#endif
