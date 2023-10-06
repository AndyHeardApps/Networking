import Foundation

public protocol HTTPControllerDelegate {
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        prepareRequestForSubmission request: Request,
        using coders: DataCoders
    ) throws -> any HTTPRequest<Data, Request.Response>
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        decodeResponse response: HTTPResponse<Data>,
        fromRequest request: Request,
        using coders: DataCoders
    ) throws -> HTTPResponse<Request.Response>
    
    func controller(
        _ controller: HTTPController,
        didRecieveError error: Error,
        from response: HTTPResponse<Data>
    ) -> Error
}

extension HTTPControllerDelegate {
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        prepareRequestForSubmission request: Request,
        using coders: DataCoders
    ) throws -> any HTTPRequest<Data, Request.Response> {
        
        var headers = request.headers ?? [:]
        let bodyData = try request.body.map { body in
            try request.encode(
                body: body,
                headers: &headers,
                using: coders
            )
        }
        
        return AnyHTTPRequest(
            httpMethod: request.httpMethod,
            pathComponents: request.pathComponents,
            headers: headers,
            queryItems: request.queryItems,
            body: bodyData,
            requiresAuthorization: request.requiresAuthorization,
            decode: request.decode
        )
    }
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        decodeResponse response: HTTPResponse<Data>,
        fromRequest request: Request,
        using coders: DataCoders
    ) throws -> HTTPResponse<Request.Response> {

        let transformedContents = try request.decode(
            data: response.content,
            statusCode: response.statusCode,
            using: coders
        )
        
        let transformedResponse = HTTPResponse(
            content: transformedContents,
            statusCode: response.statusCode,
            headers: response.headers
        )
        
        return transformedResponse
    }
    
    func controller(
        _ controller: HTTPController,
        didRecieveError error: Error,
        from response: HTTPResponse<Data>
    ) -> Error {
        
        error
    }
}

struct DefaultHTTPControllerDelegate: HTTPControllerDelegate {}
