import Foundation

public protocol WebSocketInterface {
    
    var output: AsyncThrowingStream<Data, Error> { get }
        
    var interfaceState: WebSocketInterfaceState { get }
        
    var interfaceCloseCode: WebSocketInterfaceCloseCode? { get }
    
    var interfaceCloseReason: String? { get }

    func open()

    func send(_ data: Data) async throws
    
    func sendPing() async throws
        
    func close(
        closeCode: WebSocketInterfaceCloseCode,
        reason: String?
    )
}
