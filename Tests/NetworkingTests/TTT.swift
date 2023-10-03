import XCTest

final class WSTests: XCTestCase {
    
    func testWebSocket() async throws {
        
        var request = URLRequest(url: URL(string: "http:127.0.0.1:8080/echo")!)
        request.addValue("TestValue", forHTTPHeaderField: "Test-Field")
        
        let task = URLSession.shared.webSocketTask(with: request)
        task.resume()
        
        do {
            try await task.send(.string("Hello"))
            let message = try await task.receive()
            print(message)
        } catch {
            print(error)
        }
    }
}
