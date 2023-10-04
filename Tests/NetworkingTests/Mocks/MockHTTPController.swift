import Foundation
import Networking

final class MockHTTPController {
    
    // MARK: - Properties
    var responseData: Data = .init()
    var responseStatusCode: HTTPStatusCode = .ok
    var responseHeaders: [AnyHashable : String] = [:]
    var responseDecoder: DataDecoder = JSONDecoder()
}

// MARK: - HTTP controller
extension MockHTTPController: HTTPController {
    
    func fetchResponse<Request: HTTPRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        let transformedData = try request.transform(
            data: responseData,
            statusCode: responseStatusCode,
            using: responseDecoder
        )
        
        let response = NetworkResponse(
            content: transformedData,
            statusCode: responseStatusCode,
            headers: responseHeaders
        )
        
        return response
    }
}
