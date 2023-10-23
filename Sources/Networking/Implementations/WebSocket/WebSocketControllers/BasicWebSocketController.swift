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
        
        let preparedRequest = try delegate.controller(
            self,
            prepareToOpenConnectionWithRequest: request
        )
        
        let webSocketInterface = try session.openConnection(
            to: preparedRequest,
            with: baseURL
        )
        
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
            pingInterval: ContinuousClock.Instant.Duration?
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
                    
                    try? await Task.sleep(for: pingInterval)
                    guard interface.interfaceState == .running else { continue }
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
        
        AsyncThrowingStream(
            Output.self,
            bufferingPolicy: .unbounded
        ) { [decode, dataCoders, interface] continuation in
            
            let task = Task.detached {
                do {
                    for try await element in interface.output {
                        
                        if Task.isCancelled { break }
                        
                        let decodedElement = try decode(element, dataCoders)
                        let yieldResult = continuation.yield(decodedElement)
                        
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
                    
                } catch let error as DecodingError {
                    continuation.finish(throwing: error)
                    
                } catch {
                    let connectionError = Error(
                        failure: "Recieve failed",
                        wrappedError: error,
                        closeCode: interface.interfaceCloseCode,
                        reason: interface.interfaceCloseReason
                    )
                    continuation.finish(throwing: connectionError)
                    
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
    
    func open() {
        
        interface.open()
    }
    
    func send(_ input: Input) async throws {
        
        do {
            let data = try encode(input, dataCoders)
            try await interface.send(data)
        } catch let error as EncodingError {
            throw error
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
