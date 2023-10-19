import Foundation

public protocol WebSocketController {
    
    func openConnection<Request: WebSocketRequest>(with request: Request) throws -> any WebSocketConnection<Request.Input, Request.Output>
}
