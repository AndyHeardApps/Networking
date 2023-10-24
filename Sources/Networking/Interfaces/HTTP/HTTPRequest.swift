import Foundation

/// Defines a type-safe abstraction for a HTTP request.
///
/// Any types implementing this protocol define a series of properties that point to an endpoint on a network. It is the job of a request to understand the data at the endpoint it is pointing to, and to be able to decode that data into some concrete Swift type. When a ``HTTPRequest`` is submitted through some ``HTTPController``, the ``encode(body:headers:using:)-1y6xr`` is used to convert the ``body-9mp51`` to `Data`, then the ``decode(data:statusCode:using:)`` function is called in order to be able to strongly type the response from the request. This tightly couples the request to the type of content it will provide.
///
/// Implementations should be lightweight, and are intended to be created and recycled quickly.
///
/// A ``HTTPRequest`` only defines ``pathComponents`` and ``queryItems`` and not a full `URL`. This is so that a `URL` can be constructed against some base `URL`, enabling the same request to be submitted against multiple environments, and to remove the opportunity to build a `URL` "stringily".
///
/// Aim to keep any logic that is needed to construct the request in the initialisers.
public protocol HTTPRequest<Body, Response> {

    /// The body type of the request.
    associatedtype Body = Never
    
    /// The response type that this request returns.
    associatedtype Response = Void

    // MARK: - Properties
    
    /// The HTTP method that this request uses.
    var httpMethod: HTTPMethod { get }
    
    /// The path components of the request `URL`. These will be combined in order to build the `URL`, so there is no need to include any `/`.
    var pathComponents: [String] { get }
    
    /// The headers of the request.
    var headers: [String : String]? { get }
    
    /// The query items of the request `URL`.
    var queryItems: [String : String]? { get }
    
    /// The body of the request.
    var body: Body? { get }
    
    /// Whether or not the request will require authorization credentials attaching. If so, then ``AuthorizingHTTPController`` and ``ReauthorizingHTTPController`` types will authorize the request before submission.
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    
    /// Encodes the request ``HTTPRequest/body-9pm74`` in to `Data`. This is only called by a ``HTTPController`` if the body is not `nil`.
    ///
    /// The default implementation (if the ``Body`` conforms to `Encodable`) encodes the ``body-9mp51`` to JSON and adds `application/json` to the `Content-Type` header.
    ///
    /// Any custom implementations should be sure to set the `Content-Type` value.
    ///
    /// - Parameters:
    ///   - body: The body to encode to `Data`.
    ///   - headers: The headers provided as an `inout` parameter. These should be modified to include the  `Content-Type` of the encoding method.
    ///   - coders: A collection of ``DataCoders`` to be used to encode the provided ``Body`` instance.
    /// - Returns: A data representation of the ``HTTPRequest/body-9mp51``
    /// - Throws: Any errors that occured during encoding. This is most likely to be an `EncodingError` or due to a ``DataEncoder`` not being available for a specific ``HTTPContentType``.
    func encode(
        body: Body,
        headers: inout [String : String],
        using coders: DataCoders
    ) throws -> Data
    
    /// Decodes the raw `Data` returned over the network into some concrete Swift type.
    ///
    /// It is best practice to check that the `statusCode` is expected before attempting to decode any data. If an unexpected value is encountered, then the `statusCode` can be thrown as an error.
    /// - Parameters:
    ///   - data: The `Data` returned from the network that needs to be decoded.
    ///   - statusCode: The ``HTTPStatusCode`` returned from the network.
    ///   - coders: A collection of ``DataCoders`` to be used to decode the provided `Data`. If the request "knows better" than to use these coders, then it should use some other instance.
    /// - Returns: The decoded object.
    /// - Throws: Any errors that occured during decoding. This is most likely to be an unexpected ``HTTPStatusCode`` or a `DecodingError`.
    func decode(
        data: Data,
        statusCode: HTTPStatusCode,
        using coders: DataCoders
    ) throws -> Response
}

extension HTTPRequest {
    
    public var headers: [String : String]? {
        nil
    }
    
    public var queryItems: [String : String]? {
        nil
    }
    
    public var requiresAuthorization: Bool {
        false
    }
}

extension HTTPRequest where Body == Never {
    
    public var body: Body? {
        nil
    }
}

extension HTTPRequest where Body: Encodable {
    
    public func encode(
        body: Body,
        headers: inout [String : String],
        using coders: DataCoders
    ) throws -> Data {
        
        headers["Content-Type"] = HTTPContentType.json.name
        return try coders.requireEncoder(for: .json).encode(body)
    }
}

/*
 swift package --allow-writing-to-directory ./docs generate-documentation --target Networking --disable-indexing --transform-for-static-hosting --hosting-base-path Networking --output-path ./docs
 
  I am NOT figuring this out again!
 */
