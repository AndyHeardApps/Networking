import Foundation

public protocol WebSocketRequest<Input, Output> {

    associatedtype Input
    
    associatedtype Output

    // MARK: - Properties
    var pathComponents: [String] { get }
    var headers: [String : String]? { get }
    var queryItems: [String : String]? { get }
    
    // MARK: - Functions
    func encode(
        input: Input,
        using coders: DataCoders
    ) throws -> Data
    
    func decode(
        data: Data,
        using coders: DataCoders
    ) throws -> Output
}

extension WebSocketRequest {
    
    public var headers: [String : String]? {
        nil
    }
    
    public var queryItems: [String : String]? {
        nil
    }
}

extension WebSocketRequest where Input: Encodable {
    
    public func encode(
        input: Input,
        using coders: DataCoders
    ) throws -> Data {
        
        try coders.requireEncoder(for: .json).encode(input)
    }
}

extension WebSocketRequest where Output: Decodable {
    
    public func decode(
        data: Data,
        using coders: DataCoders
    ) throws -> Output {
        
        try coders.requireDecoder(for: .json).decode(Output.self, from: data)
    }
}
