import Foundation

public protocol WebSocketConnection<Input, Output> {
    
    associatedtype Input
    
    associatedtype Output
    
    var isConnected: Bool { get }
    
    var output: AsyncThrowingStream<Output, Error> { get }
    
    func send(_ input: Input) async throws
    
    func close()
}
