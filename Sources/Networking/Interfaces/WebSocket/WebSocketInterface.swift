import Foundation

/// An interface that can be used to open a connection to the web socket, send and recieve raw `Data`, send `ping` messages, and close the connection.
public protocol WebSocketInterface: Sendable {
    
    /// A sequence emitting the messages recieved from the web socket.
    var output: AsyncThrowingStream<Data, Error> { get }
        
    /// The ``WebSocketInterfaceState`` of the interface.
    var interfaceState: WebSocketInterfaceState { get }
        
    /// The ``WebSocketInterfaceCloseCode`` of the interface. If the web socket has not been closed, this should be `nil`.
    var interfaceCloseCode: WebSocketInterfaceCloseCode? { get }
    
    /// The close reason of the interface. If the web socket has not been closed, this should be `nil`.
    var interfaceCloseReason: String? { get }

    /// Opens the connection to the web socket, alloing `Data` to be sent and recieved.
    func open()

    /// Sends the raw `Data` to the web socket.
    func send(_ data: Data) async throws
    
    /// Sends a `ping` message, returning when the corresponding `pong` message is recieved.
    func sendPing() async throws
        
    /// Closes the interface, disconnecting from the web socket server.
    /// - Parameters:
    ///   - closeCode: The code describing how the connection is being closed.
    ///   - reason: Any additional information on why the connection is being closed.
    func close(
        closeCode: WebSocketInterfaceCloseCode,
        reason: String?
    )
}
