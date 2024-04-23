import Networking

@available(iOS 17.0, *)
final class MockWebSocketControllerDelegate {
    
    // MARK: - Properties
    var pingInterval: ContinuousClock.Instant.Duration?
}

// MARK: - Web socket controller delegate
@available(iOS 17.0, *)
extension MockWebSocketControllerDelegate: WebSocketControllerDelegate {
    
    func controller(
        _ controller: WebSocketController,
        pingIntervalForRequest request: some WebSocketRequest
    ) -> ContinuousClock.Instant.Duration? {
        
        pingInterval
    }
}
