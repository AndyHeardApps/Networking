/// Defines the state of an open ``WebSocketInterface``.
public enum WebSocketInterfaceState {
    
    // MARK: - Cases
    
    /// The web socket interface is not yet open.
    case idle
    
    /// The web socket interface is open and running.
    case running
    
    /// The web socket interface has been closed and can no longer be used.
    case completed
}
