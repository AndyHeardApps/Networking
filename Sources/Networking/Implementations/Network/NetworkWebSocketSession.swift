import Foundation

public struct NetworkWebSocketSession<Input, Output> {
        
    // MARK: - Properties
    var state: State
    var messages: AsyncThrowingStream<Output, Error>
    var maximumMessageSize: Int
}

public extension NetworkWebSocketSession {
    
    func send(_ input: Input) async throws {
        
    }
    
    func sendPing() async throws {
        
    }
    
    func close(
        code: CloseCode = .normalClosure,
        reason: Data? = nil
    ) {
        
    }
}

// MARK: - Close code
extension NetworkWebSocketSession {
    public enum CloseCode {
        
        case invalid
        case normalClosure
        case goingAway
        case protocolError
        case unsupportedData
        case noStatusReceived
        case abnormalClosure
        case invalidFramePayloadData
        case policyViolation
        case messageTooBig
        case mandatoryExtensionMissing
        case internalServerError
        case tlsHandshakeFailure
    }
}

// MARK: - State
extension NetworkWebSocketSession {
    public enum State {
        
        case idle
        case running
        case completed(closeCode: CloseCode, reason: Data?)
        case failed(Error?)
    }
}
