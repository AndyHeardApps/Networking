import XCTest
@testable import Networking

@available(iOS 17.0, *)
final class URLSessionWebSocketTaskWebSocketInterfaceTests: XCTestCase {
    
    // MARK: - Properties
    private let server: MockWebSocketServer = {
        let server = MockWebSocketServer()
        try! server.start()
        return server
    }()
    private let url = URL(string: "ws://localhost:12345")!
}

// MARK: - Tests
@available(iOS 17.0, *)
extension URLSessionWebSocketTaskWebSocketInterfaceTests {
    
    func test_interfaceState_willReturnCorrectValues() async throws {
        
        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)

        XCTAssertEqual(task.interfaceState, .idle)
        task.open()
        XCTAssertEqual(task.interfaceState, .running)
        task.close(closeCode: .goingAway, reason: nil)
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertEqual(task.interfaceState, .completed)
    }
    
    func test_sendAndReceiveData() async throws {
        
        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)

        let dataArray = [
            Data(UUID().uuidString.utf8),
            Data(UUID().uuidString.utf8),
            Data(UUID().uuidString.utf8)
        ]
        
        task.open()

        for data in dataArray {
            try await task.send(data)
        }
        
        var index = 0
        for try await recievedData in task.output.prefix(3) {
            XCTAssertEqual(recievedData, dataArray[index])
            index += 1
        }
    }
    
    func test_taskCancellation_willReportErrorGracefully() async throws {
        
        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)
        task.open()
        
        try await task.send(.init())
        task.close(closeCode: .normalClosure, reason: "Going away")
        
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertNotNil(task.interfaceCloseCode)
        XCTAssertEqual(task.interfaceCloseReason, "Going away")
    }
    
    func test_sendPing() async throws {
        
        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)
        task.open()

        try await task.sendPing()
    }
}
