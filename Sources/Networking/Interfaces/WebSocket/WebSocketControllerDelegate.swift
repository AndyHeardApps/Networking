import Foundation

public protocol WebSocketControllerDelegate {
    
    // MARK: - Functions
    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> UInt?
}

extension WebSocketControllerDelegate {
    
    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> UInt? {
        
        nil
    }
}

struct DefaultWebSocketControllerDelegate: WebSocketControllerDelegate {}
