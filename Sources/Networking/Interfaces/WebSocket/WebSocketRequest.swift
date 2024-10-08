import Foundation

/// Defines a type-safe abstraction for a request that opens a connection to a web socket.
///
/// Any types implementing this protocol define a series of properties that point to a web socket on a network. It is the job of a request to understand the data that can be sent to and received from the web socket, and to be able to decode that data into some concrete Swift type. When a ``WebSocketRequest`` is submitted through some ``WebSocketController``, the ``encode(input:using:)-1vto4`` is used to convert the ``Input`` to `Data`, then the ``decode(data:using:)-6zk91`` function is called in order to be able to strongly type the ``Output`` from the web socket. This tightly couples the request to the type of content it will send and recieve.
///
/// Implementations should be lightweight, and are intended to be created and recycled quickly.
///
/// A ``WebSocketRequest`` only defines ``pathComponents`` and ``queryItems`` and not a full `URL`. This is so that a `URL` can be constructed against some base `URL`, enabling the same request to be submitted against multiple environments, and to remove the opportunity to build a `URL` "stringily".
///
/// Aim to keep any logic that is needed to construct the request in the initialisers.
public protocol WebSocketRequest<Input, Output>: Sendable {

    /// The type that this request can send to the opened web socket.
    associatedtype Input
    
    /// The type that this request can recieve from the opened web socket.
    associatedtype Output

    // MARK: - Properties
    
    /// The path components of the request `URL`. These will be combined in order to build the `URL`, so there is no need to include any `/`.
    var pathComponents: [String] { get }
    
    /// The headers of the request.
    var headers: [String : String]? { get }
    
    /// The query items of the request `URL`.
    var queryItems: [String : String]? { get }

    /// The maximum number of bytes to buffer before the receive call fails with an error.
    var maximumMessageSize: Int? { get }

    // MARK: - Functions
    
    /// Encodes <doc:/documentation/Networking/WebSocketRequest/Input> instances in to `Data`. This is called by a ``WebSocketController``.
    ///
    /// The default implementation (if the <doc:/documentation/Networking/WebSocketRequest/Input> conforms to `Encodable`) encodes the `input` to JSON.
    ///
    /// - Parameters:
    ///   - input: The <doc:/documentation/Networking/WebSocketRequest/Input> to encode to `Data`.
    ///   - coders: A collection of ``DataCoders`` to be used to encode the provided <doc:/documentation/Networking/WebSocketRequest/Input> instance.
    /// - Returns: A data representation of the `input`.
    /// - Throws: Any errors that occured during encoding. This is most likely to be an `EncodingError` or due to a ``DataEncoder`` not being available for a specific ``HTTPContentType``.
    func encode(
        input: Input,
        using coders: DataCoders
    ) throws -> Data
    
    /// Decodes <doc:/documentation/Networking/WebSocketRequest/Output> instances from data. This is called by a ``WebSocketController``.
    ///
    /// The default implementation (if the <doc:/documentation/Networking/WebSocketRequest/Output> conforms to `Decodable`) treats the `data` as JSON and attempts to decode it into an <doc:/documentation/Networking/WebSocketRequest/Output> instance.
    ///
    /// - Parameters:
    ///   - data: The `Data` to attempt to convert into some <doc:/documentation/Networking/WebSocketRequest/Output>.
    ///   - coders: A collection of ``DataCoders`` to be used to decode the provided `Data` into some <doc:/documentation/Networking/WebSocketRequest/Output> instance.
    /// - Returns: An <doc:/documentation/Networking/WebSocketRequest/Output> decoded from the `data`.
    /// - Throws: Any errors that occured during decoding. This is most likely to be a `DecodingError` or due to a ``DataDecoder`` not being available for a specific ``HTTPContentType``.
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

    public var maximumMessageSize: Int? {
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
