import Foundation
import Network

actor MockWebSocketServer {

    // MARK: - Properties
    private var connections: [NWConnection] = []
    private var listener: NWListener?
    private let dispatchQueue = DispatchQueue(label: "mock-websocket-server")
    
    // MARK: - Deinit
    deinit {
        
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener?.cancel()
    }
}

extension MockWebSocketServer {

    private func startReceive(connection: NWConnection) {
        
        connection.receiveMessage { [weak self] content, context, _, error in

            if let error {
                print("Connection receive did fail, error: \(error)")
                return
            }
            
            if let content, let context {
                print("Connection did receive content, count: \(content.count)")
                Task { [weak self] in
                    await self?.send(
                        data: content,
                        to: connection,
                        with: context
                    )
                }
            }
            
            Task { [weak self] in
                await self?.startReceive(connection: connection)
            }
        }
    }
    
    private func send(
        data: Data,
        to connection: NWConnection,
        with incomingContext: NWConnection.ContentContext
    ) {
        
        let opCode: NWProtocolWebSocket.Opcode
        if
            let webSocketMetadata = incomingContext.protocolMetadata.first as? NWProtocolWebSocket.Metadata,
            webSocketMetadata.opcode == .ping
        {
            opCode = .pong
        } else {
            opCode = .text
        }

        let message = NWProtocolWebSocket.Metadata(opcode: opCode)
        let context = NWConnection.ContentContext(
            identifier: "send",
            metadata: [message]
        )

        connection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed { error in
            if let error {
                print("Send failed: \(error.localizedDescription)")
            }
        })
    }

    func start() throws {
        
        guard listener == nil else {
            return
        }
        
        print("will open")

        let parameters = NWParameters.tcp
        let ws = NWProtocolWebSocket.Options(.version13)
        parameters.defaultProtocolStack.applicationProtocols.insert(ws, at: 0)
        let listener = try NWListener(using: parameters, on: 12345)

        listener.stateUpdateHandler = { newState in
            print("listener state did change, new: \(newState)")
        }
        
        listener.newConnectionHandler = { [weak self, dispatchQueue] connection in
            
            print("listener did accept connection")
            Task { [weak self] in
                await self?.append(connection)
            }

            connection.stateUpdateHandler = { newState in
                print("connection state did change, new: \(newState)")
            }
            
            connection.start(queue: dispatchQueue)
            
            Task { [weak self] in
                await self?.startReceive(connection: connection)
            }
        }
        listener.start(queue: dispatchQueue)

        self.listener = listener
    }

    private func append(_ connection: NWConnection) {
        self.connections.append(connection)
    }

    func cancel() {
        
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener?.cancel()
    }
}
