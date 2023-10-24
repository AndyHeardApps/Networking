import Foundation

/// Defines a type that can create web socket interfaces for sending an recieving raw `Data` through a websocket, and send `ping` and recieve `pong` messages.
public protocol WebSocketSession {
    
    /// Creates a new ``WebSocketInterface`` object to the provided ``WebSocketRequest`` resolved against the base `URL`.
    ///
    /// The `baseURL`, ``WebSocketRequest/pathComponents``, and ``WebSocketRequest/queryItems-67a0r`` are combined to build the full `URL` before submission.
    ///
    /// - Parameters:
    ///   - request: The ``WebSocketRequest`` to submit.
    ///   - baseURL: The base `URL` to submit the `request` against. This base `URL` will have the ``WebSocketRequest/pathComponents`` and ``WebSocketRequest/queryItems`` appended to build the full URL.
    /// - Returns: A new ``WebSocketInterface`` that can be used with to send and recieve raw data to the web socket.
    /// - Throws: Errors that occurred during creating the connection.
    func createInterface(
        to request: some WebSocketRequest,
        with baseURL: URL
    ) throws -> WebSocketInterface
}
