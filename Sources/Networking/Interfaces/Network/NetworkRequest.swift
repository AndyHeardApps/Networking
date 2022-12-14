import Foundation

/// Defines a strongly typed abstraction for a network request.
///
/// Any types implementing this protocol define a series of properties that point to an endpoint on a network. It is the job of a request to understand the data at the endpoint it is pointing to, and to be able to decode that data into some concrete Swift type. When a ``NetworkRequest`` is submitted through some ``NetworkController``, the ``transform(data:statusCode:using:)`` function is called in order to be able to strongly type the response from the request. This tightly couples the request to the type of content it will provide.
///
/// Implementations should be lightweight, and are intended to be created and recycled quickly.
///
/// A ``NetworkRequest`` only defines ``pathComponents`` and ``queryItems`` and not a full `URL`. This is so that a `URL` can be constructed against some base `URL`, enabling the same request to be submitted against multiple environments, and to remove the opportunity to build a `URL` "stringily".
///
/// Aim to keep any logic that is needed to construct the request in the initialisers. For instance, use a throwing initialiser and a `JSONEncoder` to encode JSON `Data` into the ``body``.
public protocol NetworkRequest<ResponseType> {

    /// The strongly typed response that this request returns.
    associatedtype ResponseType

    // MARK: - Properties
    
    /// The HTTP method that this request uses.
    var httpMethod: HTTPMethod { get }
    
    /// The path components of the request `URL`. These will be combined in order to build the `URL`, so there is not need to include any `/`.
    var pathComponents: [String] { get }
    
    /// The headers of the request.
    var headers: [String : String]? { get }
    
    /// The query items of the request `URL`.
    var queryItems: [String : String]? { get }
    
    /// The body of the request.
    var body: Data? { get }
    
    /// Whether or not the request will require authorization credentials attaching. If so, then ``AuthorizingNetworkController`` and ``ReauthorizingNetworkController`` types will authorize the request before submission.
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    
    /// Transforms the raw `Data` returned over the network into some concrete Swift type.
    ///
    /// It is best practice to check that the `statusCode` is expected before attempting to decode any data. If an unexpected value is encountered, then the `statusCode` can be thrown as an error.
    /// - Parameters:
    ///   - data: The `Data` returned from the network that needs to be decoded.
    ///   - statusCode: The ``HTTPStatusCode`` returned from the network.
    ///   - decoder: A ``DataDecoder`` provided by the calling ``NetworkController`` that can be used to decode the `Data`. This usually has API specific settings such as date decoding options. If the request "knows better" than to use this default decoder, then it should use some other instance.
    /// - Returns: The decoded object.
    /// - Throws: Any errors that occured during decoding. This is most likely to be an unexpeced ``HTTPStatusCode`` or a `DecodingError`.
    func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> ResponseType
}
