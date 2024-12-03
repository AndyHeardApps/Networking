import Foundation

/// Provides callbacks to customise ``WebSocketRequest`` objects before they are opened, and allows customisation of ping and pong message timings.
@available(iOS 17.0, *)
public protocol WebSocketControllerDelegate: Sendable {

    // MARK: - Functions
    
    /// Prepares a ``WebSocketRequest`` for submission.
    ///
    /// The default implementation returns the request unmodified.
    ///
    /// - Parameters:
    ///   - controller: The calling ``WebSocketController``.
    ///   - request: The ``WebSocketRequest`` to be prepared for submission.
    /// - Returns: A  potentially modified ``WebSocketRequest`` with the same ``WebSocketRequest/Input`` and ``WebSocketRequest/Output`` as the provided request.
    /// - Throws: Any errors preventing the user being prepared for submission.
    func controller<Request: WebSocketRequest>(
        _ controller: WebSocketController,
        prepareToOpenConnectionWithRequest request: Request
    ) throws -> any WebSocketRequest<Request.Input, Request.Output>
    
    /// Defines a ping interval for a ``WebSocketConnection`` opened by the provided ``WebSocketRequest``.
    ///
    /// The default value is `nil`.
    ///
    /// - Parameters:
    ///   - controller: The calling ``WebSocketController``.
    ///   - request: The ``WebSocketRequest`` to provide a ping interval for.
    /// - Returns: A time interval that the new connection will use to send ping intervals.
    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> ContinuousClock.Instant.Duration?
}

@available(iOS 17.0, *)
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
