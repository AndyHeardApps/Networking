import Foundation

// MARK: - Response transform
extension NetworkController {
    
    func transform<Request: NetworkRequest>(
        dataResponse: NetworkResponse<Data>,
        from request: Request,
        using decoder: DataDecoder
    ) throws -> NetworkResponse<Request.ResponseType> {
        
        let transformedContents = try request.transform(
            data: dataResponse.content,
            statusCode: dataResponse.statusCode,
            using: decoder
        )
        
        let transformedResponse = NetworkResponse(
            content: transformedContents,
            statusCode: dataResponse.statusCode,
            headers: dataResponse.headers
        )
        
        return transformedResponse
    }
}

// MARK: - Request modification
extension NetworkController {
    
    func add<Request: NetworkRequest>(
        universalHeaders: [String : String]?,
        to request: Request
    ) -> any NetworkRequest<Request.ResponseType> {
        
        guard let universalHeaders else {
            return request
        }
        
        var headers = request.headers ?? [:]
        headers.merge(universalHeaders) { requestHeader, universalHeader in
            requestHeader
        }
        
        let updatedRequest = AnyRequest(
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
