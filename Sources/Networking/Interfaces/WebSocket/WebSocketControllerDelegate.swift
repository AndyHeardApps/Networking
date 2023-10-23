import Foundation

public protocol WebSocketControllerDelegate {
    
    // MARK: - Functions
    func controller<Request: WebSocketRequest>(
        _ controller: WebSocketController,
        prepareToOpenConnectionWithRequest request: Request
    ) throws -> any WebSocketRequest<Request.Input, Request.Output>

    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> ContinuousClock.Instant.Duration?
}

extension WebSocketControllerDelegate {
    
    public func controller<Request: WebSocketRequest>(
        _ controller: WebSocketController,
        prepareToOpenConnectionWithRequest request: Request
    ) throws -> any WebSocketRequest<Request.Input, Request.Output> {
        request
    }

    public func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> ContinuousClock.Instant.Duration? {
        
        nil
    }
}

struct DefaultWebSocketControllerDelegate: WebSocketControllerDelegate {}
