import Foundation

/// Defines an interface for a connection to a web socket.
/// 
/// The socket can be connected using the ``open()`` function and closed with the ``close()`` function only once, but while open (``isConnected`` is `true`) , values can be sent with the ``send(_:)`` function and received by listening to the ``output-swift.property``.
public protocol WebSocketConnection<Input, Output> {
    
    /// The type that this web socket connection sends.
    associatedtype Input
    
    /// The type that this web socket connection recieves.
    associatedtype Output
    
    /// Returns whether or not the connection is currently open and connected.
    var isConnected: Bool { get }
    
    /// Opens this connection so that messages can be sent and recieved.
    func open()
    
    /// The recieved messages from the web socket.
    var output: AsyncThrowingStream<Output, Error> { get }
    
    /// Sends a message through the web socket.
    func send(_ input: Input) async throws
    
    /// Closes the web socket. Rendering this object unusable, meaning it should be discarded.
    func close()
}
