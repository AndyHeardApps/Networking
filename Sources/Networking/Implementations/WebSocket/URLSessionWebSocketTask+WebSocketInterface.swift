import Foundation

extension URLSessionWebSocketTask: WebSocketInterface {
    
    public var interfaceState: WebSocketInterfaceState {

        switch self.state {
        case .running:
            .running
        case .suspended:
            .idle
        case .canceling:
            .completed
        case .completed:
            .completed
        @unknown default:
            .completed
        }
    }
    
    public var interfaceCloseCode: WebSocketInterfaceCloseCode? {
        
        switch closeCode {
        case .invalid:
            .invalid
        case .normalClosure:
            .normalClosure
        case .goingAway:
            .goingAway
        case .protocolError:
            .protocolError
        case .unsupportedData:
            .unsupportedData
        case .noStatusReceived:
            .noStatusReceived
        case .abnormalClosure:
            .abnormalClosure
        case .invalidFramePayloadData:
            .invalidFramePayloadData
        case .policyViolation:
            .policyViolation
        case .messageTooBig:
            .messageTooBig
        case .mandatoryExtensionMissing:
            .mandatoryExtensionMissing
        case .internalServerError:
            .internalServerError
        case .tlsHandshakeFailure:
            .tlsHandshakeFailure
        @unknown default:
            .noStatusReceived
        }
    }
    
    public var interfaceCloseReason: String? {
        
        guard let closeReason else {
            return nil
        }
        
        return String(data: closeReason, encoding: .utf8)
    }
    
    public var output: AsyncThrowingStream<Data, Error> {
        
        AsyncThrowingStream(
            Data.self,
            bufferingPolicy: .unbounded
        ) { [weak self] continuation in
            
            let task = Task.detached { [weak self] in
                do {
                    while let element = try await self?.receive() {
                        
                        if Task.isCancelled { break }
                        
                        let yieldResult = switch element {
                        case let .data(data):
                            continuation.yield(data)
                        case let .string(string):
                            continuation.yield(Data(string.utf8))
                        @unknown default:
                            continuation.yield(Data())
                        }
                        
                        let shouldBreak: Bool
                        switch yieldResult {
                        case .enqueued, .dropped:
                            shouldBreak = false
                        case .terminated:
                            shouldBreak = true
                        @unknown default:
                            shouldBreak = true
                        }
                        
                        if shouldBreak {
                            break
                        }
                    }
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                    
                }
            }
            
            continuation.onTermination = { termination in
                switch termination {
                case .finished:
                    break
                case .cancelled:
                    task.cancel()
                @unknown default:
                    task.cancel()
                }
            }
        }
    }
    
    public func start() {
        
        resume()
    }
    
    public func send(_ data: Data) async throws {
        
        try await send(.data(data))
    }
    
    public func sendPing() async throws {

        try await withUnsafeThrowingContinuation { [weak self] continuation in
            
            guard let `self` else {
                continuation.resume()
                return
            }
            
            self.sendPing { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    public func close(
        closeCode: WebSocketInterfaceCloseCode,
        reason: String?
    ) {
        
        let mappedCloseCode: URLSessionWebSocketTask.CloseCode = switch closeCode {
        case .invalid:
            .invalid
        case .normalClosure:
            .normalClosure
        case .goingAway:
            .goingAway
        case .protocolError:
            .protocolError
        case .unsupportedData:
            .unsupportedData
        case .noStatusReceived:
            .noStatusReceived
        case .abnormalClosure:
            .abnormalClosure
        case .invalidFramePayloadData:
            .invalidFramePayloadData
        case .policyViolation:
            .policyViolation
        case .messageTooBig:
            .messageTooBig
        case .mandatoryExtensionMissing:
            .mandatoryExtensionMissing
        case .internalServerError:
            .internalServerError
        case .tlsHandshakeFailure:
            .tlsHandshakeFailure
        }
        
        self.cancel(
            with: mappedCloseCode,
            reason: reason.map { Data($0.utf8) }
        )
    }
}
