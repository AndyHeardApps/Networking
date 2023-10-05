import Foundation
@testable import Networking

extension HTTPRequestBody: Hashable {
    
    public static func == (lhs: HTTPRequestBody, rhs: HTTPRequestBody) -> Bool {
        
        switch (lhs, rhs) {
        case let (.data(lhs), .data(rhs)):
            return lhs == rhs
            
        case let (.json(lhs), .data(rhs)):
            
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .sortedKeys
            
            do {
                return try jsonEncoder.encode(lhs) == jsonEncoder.encode(rhs)
            } catch {
                return false
            }
            
        default:
            return false
            
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        
        switch self {
        case let .json(json):
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .sortedKeys

            do {
                try hasher.combine(jsonEncoder.encode(json))
            } catch {}
            
        case let .data(data):
            hasher.combine(data)

        }
    }
}
