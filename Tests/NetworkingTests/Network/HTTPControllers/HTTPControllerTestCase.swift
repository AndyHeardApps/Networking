import Networking

// Shared helpers for HTTPController tests
protocol HTTPControllerTestCase {
    
    var universalHeaders: [String : String]! { get }
}

extension HTTPControllerTestCase {
    
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
