import Foundation
@testable import Networking

final class MockReauthorizingHTTPControllerDelegate: @unchecked Sendable {
    
    // MARK: - Properties
    private(set) var controllerPreparingRequest: HTTPController?
    private(set) var requestPreparedForSubmission: (any HTTPRequest)?
    private(set) var codersUsedForRequestPreparation: DataCoders?
    
    private(set) var controllerDecodingRequest: HTTPController?
    private(set) var decodedResponse: HTTPResponse<Data>?
    private(set) var decodedRequest: (any HTTPRequest)?
    private(set) var codersUsedForRequestDecoding: DataCoders?

    private(set) var controllerThrowingError: HTTPController?
    private(set) var handledError: Error?
    private(set) var handledErrorResponse: HTTPResponse<Data>?
    
    private(set) var controllerAttemptingReauthorization: HTTPController?
    private(set) var errorTriggeringReauthorization: Error?
    private(set) var responseTriggeringReauthorization: HTTPResponse<Data>?

    var errorToThrow: Error?
}

// MARK: - HTTP controller delegate
extension MockReauthorizingHTTPControllerDelegate: ReauthorizingHTTPControllerDelegate {
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        prepareRequestForSubmission request: Request,
        using coders: DataCoders
    ) throws -> any HTTPRequest<Data, Request.Response> {
        
        controllerPreparingRequest = controller
        requestPreparedForSubmission = request
        codersUsedForRequestPreparation = coders
        
        return try DefaultHTTPControllerDelegate()
            .controller(
                controller,
                prepareRequestForSubmission: request,
                using: coders
            )
    }
    
    func controller<Request: HTTPRequest>(
        _ controller: HTTPController,
        decodeResponse response: HTTPResponse<Data>,
        fromRequest request: Request,
        using coders: DataCoders
    ) throws -> HTTPResponse<Request.Response> {
        
        controllerDecodingRequest = controller
        decodedResponse = response
        decodedRequest = request
        codersUsedForRequestDecoding = coders

        return try DefaultHTTPControllerDelegate()
            .controller(
                controller,
                decodeResponse: response,
                fromRequest: request,
                using: coders
            )
    }
    
    func controller(
        _ controller: HTTPController,
        didRecieveError error: Error,
        from response: HTTPResponse<Data>,
        using coders: DataCoders
    ) -> Error {
        
        controllerThrowingError = controller
        handledError = error
        handledErrorResponse = response
        
        return DefaultHTTPControllerDelegate()
            .controller(
                controller,
                didRecieveError: errorToThrow ?? error,
                from: response,
                using: coders
            )
    }
    
    func controller(
        _ controller: HTTPController,
        shouldAttemptReauthorizationAfterCatching error: Error,
        from response: HTTPResponse<Data>
    ) -> Bool {
        
        controllerAttemptingReauthorization = controller
        errorTriggeringReauthorization = error
        responseTriggeringReauthorization = response
        
        return DefaultReauthorizingHTTPControllerDelegate()
            .controller(
                controller,
                shouldAttemptReauthorizationAfterCatching: error,
                from: response
            )
    }
}
