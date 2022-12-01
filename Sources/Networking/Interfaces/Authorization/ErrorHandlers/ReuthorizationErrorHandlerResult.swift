import Foundation

public enum ReauthorizationErrorHandlerResult {
    
    // MARK: - Cases
    
    case attemptReauthorization
    
    case error(Error)
}
