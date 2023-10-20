import Foundation
import Networking

//struct MockWebSocketSession: WebSocketSession {
//    
//    func openConnection(
//        to request: some WebSocketRequest,
//        with baseURL: URL
//    ) throws -> WebSocketInterface {
//        
//        
//    }
//}
//
//extension MockWebSocketSession {
//    final class Interface: WebSocketInterface {
//        
//        var output: AsyncThrowingStream<Data, Error>
//        
//        var interfaceState: WebSocketInterfaceState = .idle
//        
//        var interfaceCloseCode: WebSocketInterfaceCloseCode?
//        
//        var interfaceCloseReason: String?
//        
//        func start() {
//            interfaceState = .running
//        }
//        
//        func send(_ data: Data) async throws {
//            <#code#>
//        }
//        
//        func sendPing() async throws {
//            
//        }
//        
//        func close(closeCode: Networking.WebSocketInterfaceCloseCode, reason: String?) {
//            interfaceState = .completed
//        }
//        
//    }
//}
