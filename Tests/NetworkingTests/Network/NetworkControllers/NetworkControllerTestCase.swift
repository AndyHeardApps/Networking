import Networking

// Shared helpers for NetworkController tests
protocol NetworkControllerTestCase {
    
    var universalHeaders: [String : String]! { get }
}

extension NetworkControllerTestCase {
    
    func expectedHeaders(for request: some NetworkRequest, additionalHeaders: [String : String]? = nil) -> [String : String] {
        
        var headers = request.headers ?? [:]
        headers.merge(universalHeaders) { requestHeader, universalHeader in
            requestHeader
        }
        
        if let additionalHeaders {
            headers.merge(additionalHeaders) { requestHeader, additionalHeader in
                additionalHeader
            }
        }
        
        return headers
    }
}
