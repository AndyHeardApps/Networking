import Foundation
//
//extension URLSessionWebSocketTask: NetworkWebSocketSession {
//    
//    public typealias Input = Data
//    public typealias Output = Data
//
//    public var currentState: NetworkWebSocketSessionState {
//        
//        switch state {
//        case .running:
//            .running
//        case .suspended:
//            .idle
//        case .canceling:
//            if let error {
//                .failed(error)
//            } else {
//                .completed(closeCode: closeCode.networkingValue, reason: closeReason)
//            }
//        case .completed:
//            .completed(closeCode: closeCode.networkingValue, reason: closeReason)
//        @unknown default:
//            .idle
//        }
//    }
//    
//    public var messages: AsyncThrowingStream<Data, Error> {
//        
//        AsyncThrowingStream {
//            switch try await self.receive() {
//            case let .data(data):
//                return data
//            case let .string(string):
//                return Data(string.utf8)
//            @unknown default:
//                assertionFailure("Unknown websocket message type")
//                return Data()
//            }
//        }
//    }
//    
//    public func send(_ input: Data) async throws {
//        
//        try await send(.data(input))
//    }
//    
//    public func sendPing() async throws {
//        
//        try await withUnsafeThrowingContinuation { [weak self] (continuation: UnsafeContinuation<Void, Error>) in
//          
//            guard let self else {
//                continuation.resume()
//                return
//            }
//            
//            self.sendPing { error in
//                if let error {
//                    continuation.resume(throwing: error)
//                } else {
//                    continuation.resume()
//                }
//            }
//        }
//    }
//
//    public func close(code: NetworkWebSocketSessionCloseCode, reason: Data?) {
//        
//        cancel(with: code.urlSessionValue, reason: reason)
//    }
//}
//
//// MARK: - Close code
//extension NetworkWebSocketSessionCloseCode {
//    
//    fileprivate var urlSessionValue: URLSessionWebSocketTask.CloseCode {
//        
//        switch self {
//        case .invalid:
//            .invalid
//            
//        case .normalClosure:
//            .normalClosure
//            
//        case .goingAway:
//            .goingAway
//            
//        case .protocolError:
//            .protocolError
//            
//        case .unsupportedData:
//            .unsupportedData
//            
//        case .noStatusReceived:
//            .noStatusReceived
//            
//        case .abnormalClosure:
//            .abnormalClosure
//            
//        case .invalidFramePayloadData:
//            .invalidFramePayloadData
//            
//        case .policyViolation:
//            .policyViolation
//            
//        case .messageTooBig:
//            .messageTooBig
//            
//        case .mandatoryExtensionMissing:
//            .mandatoryExtensionMissing
//            
//        case .internalServerError:
//            .internalServerError
//            
//        case .tlsHandshakeFailure:
//            .tlsHandshakeFailure
//            
//        }
//    }
//}
//
//extension URLSessionWebSocketTask.CloseCode {
//    
//    fileprivate var networkingValue: NetworkWebSocketSessionCloseCode {
//        
//        switch self {
//        case .invalid:
//            .invalid
//            
//        case .normalClosure:
//            .normalClosure
//            
//        case .goingAway:
//            .goingAway
//            
//        case .protocolError:
//            .protocolError
//            
//        case .unsupportedData:
//            .unsupportedData
//            
//        case .noStatusReceived:
//            .noStatusReceived
//            
//        case .abnormalClosure:
//            .abnormalClosure
//            
//        case .invalidFramePayloadData:
//            .invalidFramePayloadData
//            
//        case .policyViolation:
//            .policyViolation
//            
//        case .messageTooBig:
//            .messageTooBig
//            
//        case .mandatoryExtensionMissing:
//            .mandatoryExtensionMissing
//            
//        case .internalServerError:
//            .internalServerError
//            
//        case .tlsHandshakeFailure:
//            .tlsHandshakeFailure
//            
//        @unknown default:
//            .invalid
//            
//        }
//    }
//}
