import Foundation
import Networking

struct MockWebSocketRequest: WebSocketRequest {
    
    // MARK: - Properties
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    private let _encode: (Input, DataCoders) throws -> Data
    private let _decode: (Data, DataCoders) throws -> Output

    init(
        pathComponents: [String] = ["path1", "path2"],
        headers: [String : String]? = ["header1" : "headerValue1"],
        queryItems: [String : String]? = ["query1" : "queryValue1"],
        encode: @escaping (Input, DataCoders) throws -> Data,
        decode: @escaping (Data, DataCoders) throws -> Output
    ) {
        self.pathComponents = pathComponents
        self.headers = headers
        self.queryItems = queryItems
        self._encode = encode
        self._decode = decode
    }
}

// MARK: - Coding
extension MockWebSocketRequest {
    
    func encode(input: Data, using coders: DataCoders) throws -> Data {
        
        try _encode(input, coders)
    }
    
    func decode(data: Data, using coders: DataCoders) throws -> Data {
        
        try _decode(data, coders)
    }
}
