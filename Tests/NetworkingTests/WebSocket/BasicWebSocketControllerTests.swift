import XCTest
@testable import Networking

final class BasicWebSocketControllerTests: XCTestCase {
    
    // MARK: - Properties
    private var session: MockWebSocketSession!
    private var delegate: MockWebSocketControllerDelegate!
    private var controller: BasicWebSocketController!
    private let request = MockWebSocketRequest(
        encode: { data, _ in Data(data.reversed()) },
        decode: { data, _ in data + data }
    )
}

// MARK: - Setup
extension BasicWebSocketControllerTests {
    
    override func setUp() {
        super.setUp()
        
        self.session = MockWebSocketSession()
        self.delegate = MockWebSocketControllerDelegate()
        self.controller = .init(
            baseURL: .init(string: "ws://example.domain.com")!,
            session: session,
            delegate: delegate
        )
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.session = nil
        self.delegate = nil
        self.controller = nil
    }
}

// MARK: - Tests
extension BasicWebSocketControllerTests {
    
    func test_openConnection_willUseSessionToCreateInterface() throws {
                
        _ = try controller.createConnection(with: request)
        
        XCTAssertEqual(session.openedConnections.count, 1)
        XCTAssertEqual(session.openedConnections.first?.0.pathComponents, request.pathComponents)
        XCTAssertEqual(session.openedConnections.first?.0.headers, request.headers)
        XCTAssertEqual(session.openedConnections.first?.0.queryItems, request.queryItems)
        XCTAssertEqual(session.openedConnections.first?.1.absoluteString, "ws://example.domain.com")
    }
    
    func test_openConnection_willCallOpenOnInterface() throws {
        
        let connection = try controller.createConnection(with: request)
                
        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(interface.interfaceState, .idle)
        XCTAssertFalse(connection.isConnected)
        connection.open()
        XCTAssertEqual(interface.interfaceState, .running)
        XCTAssertTrue(connection.isConnected)
    }
    
    func test_closeConnection_willCallCloseOnInterface() throws {
        
        let connection = try controller.createConnection(with: request)
                
        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }
        
        connection.open()
        XCTAssertEqual(interface.interfaceState, .running)
        XCTAssertTrue(connection.isConnected)
        connection.close()
        XCTAssertEqual(interface.interfaceState, .completed)
        XCTAssertFalse(connection.isConnected)
    }
    
    func test_send_willEncode_andSubmitDataToInterface() async throws {
        
        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        let message = Data(UUID().uuidString.utf8)
        try await connection.send(message)
        
        XCTAssertEqual(interface.sentMessages, [.data(Data(message.reversed()))])
    }
        
    func test_send_willReportConnectionErrors() async throws {
        
        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        let message = Data(UUID().uuidString.utf8)
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.sendError = MockError()

        do {
            try await connection.send(message)
            XCTFail()
        } catch {
            XCTAssertTrue(interface.sentMessages.isEmpty)
            let connectionError = error as? BasicWebSocketController.Connection<Data, Data>.Error
            XCTAssertEqual(connectionError?.failure, "Send failed")
            XCTAssertTrue(connectionError?.wrappedError is MockError)
            XCTAssertEqual(error.localizedDescription, "Send failed: MockError(): Test close reason: abnormalClosure")
        }
    }
        
    func test_send_willReportEncodingErrors() async throws {
        
        let request = MockWebSocketRequest(
            encode: { data, _ in
                throw EncodingError.invalidValue(data, .init(codingPath: [], debugDescription: "Test encoding error"))
            },
            decode: { data, _ in data + data }
        )

        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        let message = Data(UUID().uuidString.utf8)
        
        do {
            try await connection.send(message)
            XCTFail()
        } catch {
            XCTAssertTrue(interface.sentMessages.isEmpty)
            XCTAssertTrue(error is EncodingError)
        }
    }

    func test_output_willDecode_andPublishDataFromInterface() async throws {
        
        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }
        
        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        let message = Data(UUID().uuidString.utf8)
        interface.recieve(message: message)
        
        let recievedMessage = try await task.value

        XCTAssertEqual(recievedMessage, message + message)
    }
    
    func test_output_willWrapAndReportConnectionErrorsFromInterface() async throws {
     
        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.recieve(error: MockError())
        
        let recievedMessage = await task.result

        XCTAssertThrowsError(try recievedMessage.get()) { error in
            let connectionError = error as? BasicWebSocketController.Connection<Data, Data>.Error
            XCTAssertEqual(connectionError?.failure, "Recieve failed")
            XCTAssertTrue(connectionError?.wrappedError is MockError)
            XCTAssertEqual(connectionError?.closeCode, .abnormalClosure)
            XCTAssertEqual(connectionError?.reason, "Test close reason")
            XCTAssertEqual(error.localizedDescription, "Recieve failed: MockError(): Test close reason: abnormalClosure")
        }
    }
    
    func test_output_willReportDecodingErrorsFromInterface() async throws {
     
        let request = MockWebSocketRequest(
            encode: { data, _ in Data(data.reversed()) },
            decode: { data, _ in
                throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Test decoding error"))
            }
        )

        let connection = try controller.createConnection(with: request)

        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        let task = Task {
            try await connection.output.first { _ in true }
        }
        
        try await Task.sleep(for: .milliseconds(10))
        interface.interfaceCloseCode = .abnormalClosure
        interface.interfaceCloseReason = "Test close reason"
        interface.recieve(message: .init())
        
        let recievedMessage = await task.result

        XCTAssertThrowsError(try recievedMessage.get()) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func test_connection_willSendPings_basedOnDelegateProvidedInterval() async throws {
        
        delegate.pingInterval = .milliseconds(10)
        
        let connection = try controller.createConnection(with: request)
        
        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        connection.open()
        try await Task.sleep(for: .milliseconds(25))
        connection.close()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(interface.sentMessages, [.ping, .ping])
    }
    
    func test_connection_willNotSendPings_basedOnDefaultDelegate() async throws {
        
        self.controller = .init(
            baseURL: .init(string: "ws://example.domain.com")!,
            session: session
        )
        
        let connection = try controller.createConnection(with: request)
        
        guard let interface = session.lastOpenedInterface else {
            XCTFail()
            return
        }

        connection.open()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(interface.sentMessages.isEmpty)
    }
}
