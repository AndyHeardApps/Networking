import Foundation

public protocol WebSocketInterface {
    
    var output: AsyncThrowingStream<Data, Error> { get }
    
    var error: Error? { get }
    
    var interfaceState: WebSocketInterfaceState { get }
        
    var interfaceCloseCode: WebSocketInterfaceCloseCode? { get }
    
    var interfaceCloseReason: String? { get }

    func send(_ data: Data) async throws
    
    func sendPing() async throws
    
    func cancel(
        closeCode: WebSocketInterfaceCloseCode,
        reason: String?
    )
}
