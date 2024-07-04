import Foundation
import Testing
@testable import Networking

@Suite(
    "Basic web socket controller",
    .tags(.webSocket)
)
struct BasicWebSocketControllerTests {

    // MARK: - Properties
    private let session: MockWebSocketSession
    private let delegate: MockWebSocketControllerDelegate
    private let controller: BasicWebSocketController
    private let request = MockWebSocketRequest(
        encode: { data, _ in Data(data.reversed()) },
        decode: { data, _ in data + data }
    )

    // MARK: - Initializer
    init() {

        self.session = MockWebSocketSession()
        self.delegate = MockWebSocketControllerDelegate()
        self.controller = .init(
            baseURL: .init(string: "ws://example.domain.com")!,
            session: session,
            delegate: delegate
        )
    }
}

// MARK: - Tests
extension BasicWebSocketControllerTests {
    
    @Test("openConnection uses session to create interface")
    @available(iOS 17.0, *)
    func openConnectionUsesSessionToCreateInterface() throws {

        _ = try controller.createConnection(with: request)
        
        #expect(session.openedConnections.count == 1)
        #expect(session.openedConnections.first?.0.pathComponents == request.pathComponents)
        #expect(session.openedConnections.first?.0.headers == request.headers)
        #expect(session.openedConnections.first?.0.queryItems == request.queryItems)
        #expect(session.openedConnections.first?.1.absoluteString == "ws://example.domain.com")
    }
    
    @Test("openConnection calls open on interface")
    @available(iOS 17.0, *)
    func openConnectionCallsOpenOnInterface() throws {

        let connection = try controller.createConnection(with: request)
                
        let interface = try #require(session.lastOpenedInterface)

        #expect(interface.interfaceState == .idle)
        #expect(connection.isConnected == false)
        connection.open()
        #expect(interface.interfaceState == .running)
        #expect(connection.isConnected)
    }
    
    @Test("closeConnection calls close on interface")
    @available(iOS 17.0, *)
    func closeConnectionCallsCloseOnInterface() throws {

        let connection = try controller.createConnection(with: request)
                
        let interface = try #require(session.lastOpenedInterface)

        connection.open()
        #expect(interface.interfaceState == .running)
        #expect(connection.isConnected)
        connection.close()
        #expect(interface.interfaceState == .completed)
        #expect(connection.isConnected == false)
    }
    
    @Test("send encodes and submits data to interface")
    @available(iOS 17.0, *)
    func sendEncodesAndSubmitsDataToInterface() async throws {

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let message = Data(UUID().uuidString.utf8)
        try await connection.send(message)
        
        #expect(interface.sentMessages == [.data(Data(message.reversed()))])
    }
        
    @Test("send reports connection errors")
    @available(iOS 17.0, *)
    func sendReportsConnectionErrors() async throws {

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let message = Data(UUID().uuidString.utf8)
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.sendError = MockError()

        let expectedError = BasicWebSocketController.Connection<Data, Data>.Error(
            failure: "Send failed",
            wrappedError: MockError(),
            closeCode: .abnormalClosure,
            reason: "Test close reason"
        )
        await #expect(throws: expectedError) {
            try await connection.send(message)
        }
        #expect(interface.sentMessages.isEmpty)
    }
        
    @Test("send reports encoding errors")
    @available(iOS 17.0, *)
    func sendReportsEncodingErrors() async throws {

        let request = MockWebSocketRequest(
            encode: { data, _ in
                throw EncodingError.invalidValue(data, .init(codingPath: [], debugDescription: "Test encoding error"))
            },
            decode: { data, _ in data + data }
        )

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let message = Data(UUID().uuidString.utf8)
        
        await #expect(throws: EncodingError.self) {
            try await connection.send(message)
        }
        #expect(interface.sentMessages.isEmpty)
    }

    @Test("output decodes and publishes data from interface")
    @available(iOS 17.0, *)
    func outputDecodesAndPublishesDataFromInterface() async throws {

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        let message = Data(UUID().uuidString.utf8)
        interface.recieve(message: message)
        
        let recievedMessage = try await task.value

        #expect(recievedMessage == message + message)
    }
    
    @Test("output wraps and reports connection errors from interface")
    @available(iOS 17.0, *)
    func outputWrapsAndReportsConnectionErrorsFromInterface() async throws {

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.recieve(error: MockError())
        
        let recievedMessage = await task.result

        let expectedError = BasicWebSocketController.Connection<Data, Data>.Error(
            failure: "Recieve failed",
            wrappedError: MockError(),
            closeCode: .abnormalClosure,
            reason: "Test close reason"
        )
        #expect(throws: expectedError) {
            try recievedMessage.get()
        }
    }
    
    @Test("output reports decoding errors from interface")
    @available(iOS 17.0, *)
    func outputReportsDecodingErrorsFromInterface() async throws {

        let request = MockWebSocketRequest(
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Test decoding error"))
            }
        )

        let connection = try controller.createConnection(with: request)

        let interface = try #require(session.lastOpenedInterface)

        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.recieve(message: .init())
        
        let recievedMessage = await task.result

        
        #expect(throws: DecodingError.self) {
            try recievedMessage.get()
        }
    }

    @Test("connection sends pings based on delegate provided interval")
    @available(iOS 17.0, *)
    func connectionSendsPingsBasedOnDelegateProvidedInterval() async throws {

        delegate.pingInterval = .milliseconds(10)
        
        let connection = try controller.createConnection(with: request)
        
        let interface = try #require(session.lastOpenedInterface)

        connection.open()
        try await Task.sleep(for: .milliseconds(25))
        connection.close()
        try await Task.sleep(for: .milliseconds(50))

        #expect(interface.sentMessages == [.ping, .ping])
    }
    
    @Test("connection will not send pings based on default delegate")
    @available(iOS 17.0, *)
    func connectionWillNotSendPingsBasedOnDefaultDelegate() async throws {

        let controller = BasicWebSocketController(
            baseURL: .init(string: "ws://example.domain.com")!,
            session: session
        )
        
        let connection = try controller.createConnection(with: request)
        
        let interface = try #require(session.lastOpenedInterface)

        connection.open()
        try await Task.sleep(for: .milliseconds(50))

        #expect(interface.sentMessages.isEmpty)
    }
}
