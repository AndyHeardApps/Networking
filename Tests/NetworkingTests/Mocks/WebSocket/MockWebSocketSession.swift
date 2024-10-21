import Foundation
import Combine
@testable import Networking

@available(iOS 17.0, *)
final class MockWebSocketSession {
    
    // MARK: - Properties
    private(set) var openedConnections: [(any WebSocketRequest, URL)] = []
    private(set) var lastOpenedInterface: Interface?
}

@available(iOS 17.0, *)
extension MockWebSocketSession: WebSocketSession {
    
    func createInterface(
        to request: some WebSocketRequest,
        with baseURL: URL
    ) throws -> WebSocketInterface {
        
        openedConnections.append((request, baseURL))
        let interface = Interface()
        lastOpenedInterface = interface
        
        return interface
    }
}

@available(iOS 17.0, *)
extension MockWebSocketSession {
    final class Interface: WebSocketInterface, @unchecked Sendable {
        
        // Properties
        private let outputPublisher: PassthroughSubject<Data, Error> = .init()
        private(set) var sentMessages: [Message] = []
        private(set) var interfaceState: WebSocketInterfaceState = .idle
        var interfaceCloseCode: WebSocketInterfaceCloseCode?
        var interfaceCloseReason: String?
        
        var sendError: Error?
    }
}

@available(iOS 17.0, *)
extension MockWebSocketSession.Interface {
    
    func open() {
        
        interfaceState = .running
    }
    
    var output: AsyncThrowingStream<Data, Error> {
        
        outputPublisher.values.eraseToThrowingStream()
    }
    
    func send(_ data: Data) async throws {
        
        if let sendError {
            throw sendError
        } else {
            sentMessages.append(.data(data))
        }
    }
    
    func sendPing() async throws {
        
        sentMessages.append(.ping)
    }
    
    func close(
        closeCode: Networking.WebSocketInterfaceCloseCode,
        reason: String?
    ) {
        
        interfaceState = .completed
    }
}

@available(iOS 17.0, *)
extension MockWebSocketSession.Interface {
    
    func recieve(message: Data) {
        
        outputPublisher.send(message)
    }
    
    func recieve(error: Error) {
        
        outputPublisher.send(completion: .failure(error))
    }
    
    enum Message: Equatable {
        case ping
        case data(Data)
    }
}
