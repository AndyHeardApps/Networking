import Foundation
import Combine
@testable import Networking

final class MockWebSocketSession {
    
    // MARK: - Properties
    private(set) var openedConnections: [(any WebSocketRequest, URL)] = []
    private(set) var lastOpenedInterface: Interface?
}

extension MockWebSocketSession: WebSocketSession {
    
    func openConnection(
        to request: some WebSocketRequest,
        with baseURL: URL
    ) throws -> WebSocketInterface {
        
        openedConnections.append((request, baseURL))
        let interface = Interface()
        lastOpenedInterface = interface
        
        return interface
    }
}

extension MockWebSocketSession {
    final class Interface: WebSocketInterface {
        
        // Properties
        private var outputPublisher: PassthroughSubject<Data, Error> = .init()
        private(set) var sentMessages: [Message] = []
        private(set) var interfaceState: WebSocketInterfaceState = .idle
        var interfaceCloseCode: WebSocketInterfaceCloseCode?
        var interfaceCloseReason: String?
        
        var sendError: Error?
    }
}

extension MockWebSocketSession.Interface {
    
    func open() {
        
        interfaceState = .running
    }
    
    var output: AsyncThrowingStream<Data, Error> {
        
        outputPublisher.values.stream
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
