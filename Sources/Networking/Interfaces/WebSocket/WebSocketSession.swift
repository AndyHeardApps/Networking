import Foundation

public protocol WebSocketSession {
    
    func openConnection(
        to request: some WebSocketRequest,
        with baseURL: URL
    ) throws -> WebSocketInterface
}
