import Foundation

public struct BasicWebSocketController {
    
    // MARK: - Properties
    
    public let baseURL: URL
    
    public let session: WebSocketSession
    
    public let dataCoders: DataCoders
    
    public let delegate: WebSocketControllerDelegate

    // MARK: - Initialiser
    
    public init(
        baseURL: URL,
        session: WebSocketSession = URLSession.shared,
        dataCoders: DataCoders = .default,
        delegate: WebSocketControllerDelegate? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.dataCoders = dataCoders
        self.delegate = delegate ?? DefaultWebSocketControllerDelegate()
    }
}

// MARK: - Web socket controller
extension BasicWebSocketController: WebSocketController {
    
    public func openConnection<Request: WebSocketRequest>(with request: Request) throws -> any WebSocketConnection<Request.Input, Request.Output> {
        
        let webSocketInterface = try session.openConnection(to: request, with: baseURL)
        let webSocketConnection = Connection(
            interface: webSocketInterface,
            dataCoders: dataCoders,
            request: request,
            pingInterval: delegate.controller(
                self,
                pingIntervalForRequest: request
            )
        )
        
        return webSocketConnection
    }
}

// MARK: - Web socket connection
extension BasicWebSocketController {
    final class Connection<Input, Output> {
        
        // Properties
        private let interface: WebSocketInterface
        private let dataCoders: DataCoders
        private let encode: (Input, DataCoders) throws -> Data
        private let decode: (Data, DataCoders) throws -> Output
        private let pingTask: Task<Void, Never>?
        
        // Initialiser
        init(
            interface: WebSocketInterface,
            dataCoders: DataCoders,
            request: some WebSocketRequest<Input, Output>,
            pingInterval: UInt?
        ) {

            self.interface = interface
            self.dataCoders = dataCoders
            self.encode = request.encode
            self.decode = request.decode
            
            guard let pingInterval else {
                self.pingTask = nil
                return
            }
            
            self.pingTask = .init {
                while !Task.isCancelled {
                    guard interface.interfaceState == .running else { continue }
                    try? await Task.sleep(for: .seconds(pingInterval))
                    try? await interface.sendPing()
                }
            }
        }
        
        deinit {
            
            pingTask?.cancel()
        }
    }
}

extension BasicWebSocketController.Connection: WebSocketConnection {

    var isConnected: Bool {
        
        switch interface.interfaceState {
        case .idle:
            false
        case .running:
            true
        case .completed:
            false
        }
    }
    
    var output: AsyncThrowingStream<Output, Swift.Error> {
        
        interface.output
            .map { [decode, dataCoders, interface] data in
                do {
                    return try decode(data, dataCoders)
                } catch {
                    throw Error(
                        failure: "Recieve failed",
                        wrappedError: error,
                        closeCode: interface.interfaceCloseCode,
                        reason: interface.interfaceCloseReason
                    )
                }
            }
            .stream
    }
    
    func send(_ input: Input) async throws {
        
        do {
            let data = try encode(input, dataCoders)
            try await interface.send(data)
        } catch {
            throw Error(
                failure: "Send failed",
                wrappedError: error,
                closeCode: interface.interfaceCloseCode,
                reason: interface.interfaceCloseReason
            )
        }
    }
    
    func close() {
        
        pingTask?.cancel()
        
        interface.close(
            closeCode: .normalClosure,
            reason: nil
        )
    }
}

extension BasicWebSocketController.Connection {
    struct Error {
        
        let failure: String
        let wrappedError: Swift.Error
        let closeCode: WebSocketInterfaceCloseCode?
        let reason: String?
    }
}

extension BasicWebSocketController.Connection.Error: LocalizedError {
    
    var errorDescription: String? {
        
        [
            failure,
            String(describing: wrappedError),
            reason,
            closeCode.map { String(describing: $0) }
        ]
        .compactMap { $0 }
        .joined(separator: ": ")
    }
}
