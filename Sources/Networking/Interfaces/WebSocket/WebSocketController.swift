import Foundation

/// Defines a type that can create web socket connections.
///
/// The ``BasicWebSocketController`` is the only default implementation.
public protocol WebSocketController: Sendable {
    
    /// Creates a new web socket connection from the provided request.
    /// - Parameter request: The request that defines the endpoint to open the web socket connection with.
    /// - Returns: A new web socket connection with the same ``WebSocketRequest/Input`` and ``WebSocketRequest/Output`` types as the provided request.
    /// - Throws: Errors that occurred during creating the connection.
    func createConnection<Request: WebSocketRequest>(with request: Request) throws -> any WebSocketConnection<Request.Input, Request.Output>
}
