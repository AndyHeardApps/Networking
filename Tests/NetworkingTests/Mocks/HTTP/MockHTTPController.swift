import Foundation
import Networking

final class MockHTTPController {
    
    // MARK: - Properties
    var responseData: Data = .init()
    var responseStatusCode: HTTPStatusCode = .ok
    var responseHeaders: [AnyHashable : String] = [:]
}

// MARK: - HTTP controller
extension MockHTTPController: HTTPController {
    
    func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> HTTPResponse<Request.Response> {
        
        let decodedData = try request.decode(
            data: responseData,
            statusCode: responseStatusCode,
            using: .default
        )
        
        let response = HTTPResponse(
            content: decodedData,
            statusCode: responseStatusCode,
            headers: responseHeaders
        )
        
        return response
    }
}
