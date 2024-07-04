import Foundation
import Testing
@testable import Networking

@Suite(
    "URLSessionWebSocketTask WebSocketInterface",
    .tags(.webSocket)
)
@available(iOS 17.0, *)
struct URLSessionWebSocketTaskWebSocketInterfaceTests {

    // MARK: - Properties
    private let url = URL(string: "ws://localhost:12345")!
    private let server: MockWebSocketServer

    // MARK: - Initializer
    init() async throws {

        self.server = MockWebSocketServer()
        try await server.start()
    }
}

// MARK: - Tests
extension URLSessionWebSocketTaskWebSocketInterfaceTests {
    
    @Test("interfaceState returns correct values")
    @available(iOS 17.0, *)
    func interfaceStateReturnsCorrectValues() async throws {

        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)

        #expect(task.interfaceState == .idle)
        task.open()
        #expect(task.interfaceState == .running)
        task.close(closeCode: .goingAway, reason: nil)
        try await Task.sleep(for: .milliseconds(10))
        #expect(task.interfaceState == .completed)
    }
    
    @Test("Send and receive data")
    @available(iOS 17.0, *)
    func sendAndReceiveData() async throws {

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
            #expect(recievedData == dataArray[index])
            index += 1
        }
    }
    
    @Test("Task cancellation reports error gracefully")
    @available(iOS 17.0, *)
    func taskCancellationReportsErrorGracefully() async throws {

        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)
        task.open()
        
        try await task.send(.init())
        task.close(closeCode: .normalClosure, reason: "Going away")
        
        try await Task.sleep(for: .milliseconds(10))
        #expect(task.interfaceCloseCode != nil)
        #expect(task.interfaceCloseReason == "Going away")
    }
    
    @Test("Send ping")
    @available(iOS 17.0, *)
    func sendPing() async throws {

        let task: WebSocketInterface = URLSession.shared.webSocketTask(with: url)
        task.open()

        try await task.sendPing()
    }
}
