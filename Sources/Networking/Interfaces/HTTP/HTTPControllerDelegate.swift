import Foundation

/// Provides callbacks to customise ``HTTPRequest`` encoding and decoding, as well as error handling.
public protocol HTTPControllerDelegate {
    
    /// Prepares a ``HTTPRequest`` for submission.
    ///
    /// This is called after any changes have been made by a ``HTTPAuthorizationProvider``.
    ///
    /// The default implementation converts the ``HTTPRequest/body-9pm74`` of the provided `request` to JSON data using the ``HTTPRequest/encode(body:headers:using:)-1y6xr`` function.
    /// - Parameters:
    ///   - controller: The calling ``HTTPController``.
    ///   - request: The ``HTTPRequest`` to be prepared for submission.
    ///   - coders: The  ``DataCoders`` provided by the calling ``HTTPController`` available to use for encoding any content.
    /// - Returns: A ``HTTPRequest`` with a body type of `Data` and the same ``HTTPRequest/Response`` as the provided `request`.
    /// - Throws: Any errors preventing the user being prepared for submission, usually a `EncodingError`.
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        prepareRequestForSubmission request: Request,
        using coders: DataCoders
    ) throws -> any HTTPRequest<Data, Request.Response>
    
    /// Decodes raw `Data` returned by the provided ``HTTPRequest`` to the ``HTTPRequest/Response`` instance.
    ///
    /// The default implementation decodes the `Data` using the ``HTTPRequest/decode(data:statusCode:using:)`` function and constructs a new ``HTTPResponse`` with the same ``HTTPResponse/statusCode`` and ``HTTPResponse/headers``.
    /// - Parameters:
    ///   - controller: The calling ``HTTPController``.
    ///   - response: The ``HTTPResponse`` containing raw `Data` to be decoded.
    ///   - request: The ``HTTPRequest`` that returned the `response`.
    ///   - coders: The  ``DataCoders`` provided by the calling ``HTTPController`` available to use for decoding any content.
    /// - Returns: The decoded ``HTTPRequest/Response`` object.
    /// - Throws: Any error that prevented decoding. Usually this is a `DecodingError` or ``HTTPStatusCode``.
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        decodeResponse response: HTTPResponse<Data>,
        fromRequest request: Request,
        using coders: DataCoders
    ) throws -> HTTPResponse<Request.Response>
    
    /// Attempts to decode additional information from a failed ``HTTPRequest``.
    ///
    /// This can be used to decode information about the error from the provided `response`.
    ///
    /// The default implementation just returns the `error` parameter with no attempt to decode additional information.
    /// - Parameters:
    ///   - controller: The calling ``HTTPController``.
    ///   - error: The `Error` that was thrown by the controller.
    ///   - response: The accompanying ``HTTPResponse`` containing raw `Data` that produces the `error`.
    ///   - coders: The  ``DataCoders`` provided by the calling ``HTTPController`` available to use for decoding any error content.
    /// - Returns: Some `Error`, ideally with additional information on what caused the original error to be thrown.
    func controller(
        _ controller: HTTPController,
        didRecieveError error: Error,
        from response: HTTPResponse<Data>,
        using coders: DataCoders
    ) -> Error
}

extension HTTPControllerDelegate {
    
    public func controller<Request: HTTPRequest>(
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
    
    public func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        decodeResponse response: HTTPResponse<Data>,
        fromRequest request: Request,
        using coders: DataCoders
    ) throws -> HTTPResponse<Request.Response> {

        let decodedContents = try request.decode(
            data: response.content,
            statusCode: response.statusCode,
            using: coders
        )
        
        let decodedResponse = HTTPResponse(
            content: decodedContents,
            statusCode: response.statusCode,
            headers: response.headers
        )
        
        return decodedResponse
    }
    
    public func controller(
        _ controller: HTTPController,
        didRecieveError error: Error,
        from response: HTTPResponse<Data>,
        using: DataCoders
    ) -> Error {
        
        error
    }
}

struct DefaultHTTPControllerDelegate: HTTPControllerDelegate {}
