import Foundation

/// A basic implementation of the ``WebSocketController``, simply opening and returning a ``WebSocketConnection`` and handling `ping` and `pong` messages.
///
/// This type will open web socket connections using ``WebSocketRequest`` and the provided ``WebSocketSession``, encoding the ``WebSocketRequest/Input`` of the reqest using ``WebSocketRequest/encode(input:using:)-2u1ga`` and decoding the ``WebSocketRequest/Output`` using ``WebSocketRequest/decode(data:using:)-6zk91``.
///
/// For further control over preparing the requests for connection or handling `ping` messages, create a custom ``WebSocketControllerDelegate`` and provide it in the initialiser.
///
/// Though the implementation is intentionally lightweight, it is best if an instance is created once for each `baseURL` on app launch, and held for reuse.
@available(iOS 17.0, *)
public struct BasicWebSocketController {
    
    // MARK: - Properties
    
    /// The base `URL` to open web socket connections with. This is the base `URL` used to construct the full `URL` using the ``WebSocketRequest/pathComponents`` and ``WebSocketRequest/queryItems`` of the request.
    public let baseURL: URL
    
    /// The ``WebSocketSession`` used to open a ``WebSocketInterface`` to send and recieve the raw `Data` throug the web socket.
    public let session: WebSocketSession
    
    /// A collection of ``DataEncoder`` and ``DataDecoder`` objects that the controller will use to encode and decode specific message types.
    public let dataCoders: DataCoders
    
    /// The delegate used to provide additional control over preparing a request to be sent and handling `ping` messages.
    public let delegate: WebSocketControllerDelegate

    // MARK: - Initialiser
    
    #if os(iOS) || os(macOS)
    /// Creates a new ``BasicWebSocketController`` instance.
    /// - Parameters:
    ///   - baseURL: The base `URL` of the controller.
    ///   - session: The ``WebSocketSession`` the controller will use to open ``WebSocketInterface`` for a request.
    ///   - dataCoders: The ``DataCoders`` that can be used to encode and decode request input and output. By default, only JSON coders will be available.
    ///   - delegate: The ``WebSocketControllerDelegate`` for the controller to use. If none is provided, then a default implementation is used to provide standard functionality.
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
    #endif
}

// MARK: - Web socket controller
@available(iOS 17.0, *)
extension BasicWebSocketController: WebSocketController {
    
    public func createConnection<Request: WebSocketRequest>(with request: Request) throws -> any WebSocketConnection<Request.Input, Request.Output> {
        
        let preparedRequest = try delegate.controller(
            self,
            prepareToOpenConnectionWithRequest: request
        )
        
        let webSocketInterface = try session.createInterface(
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
@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
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

@available(iOS 17.0, *)
extension BasicWebSocketController.Connection {
    struct Error {
        
        let failure: String
        let wrappedError: Swift.Error
        let closeCode: WebSocketInterfaceCloseCode?
        let reason: String?
    }
}

@available(iOS 17.0, *)
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
