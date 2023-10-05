import Foundation

// MARK: - Response transform
extension HTTPController {
    
    func transform<Request: HTTPRequest>(
        dataResponse: HTTPResponse<Data>,
        from request: Request,
        using decoder: DataDecoder
    ) throws -> HTTPResponse<Request.ResponseType> {
        
        let transformedContents = try request.transform(
            data: dataResponse.content,
            statusCode: dataResponse.statusCode,
            using: decoder
        )
        
        let transformedResponse = HTTPResponse(
            content: transformedContents,
            statusCode: dataResponse.statusCode,
            headers: dataResponse.headers
        )
        
        return transformedResponse
    }
}

// MARK: - Request modification
extension HTTPController {
    
    func add<Request: HTTPRequest>(
        universalHeaders: [String : String]?,
        to request: Request
    ) -> any HTTPRequest<Request.ResponseType> {
        
        guard let universalHeaders else {
            return request
        }
        
        var headers = request.headers ?? [:]
        headers.merge(universalHeaders) { requestHeader, universalHeader in
            requestHeader
        }
        
        let updatedRequest = AnyHTTPRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: request.body,
            requiresAuthorization: request.requiresAuthorization,
            transform: request.transform
        )
        
        return updatedRequest
    }
}
