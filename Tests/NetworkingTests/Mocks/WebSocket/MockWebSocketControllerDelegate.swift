import Networking

final class MockWebSocketControllerDelegate {
    
    // MARK: - Properties
    var pingInterval: ContinuousClock.Instant.Duration?
}

// MARK: - Web socket controller delegate
extension MockWebSocketControllerDelegate: WebSocketControllerDelegate {
    
    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> ContinuousClock.Instant.Duration? {
        
        pingInterval
    }
}
