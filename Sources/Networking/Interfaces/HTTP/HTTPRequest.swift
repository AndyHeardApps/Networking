import Foundation

/// Defines a strongly typed abstraction for a HTTP request.
///
/// Any types implementing this protocol define a series of properties that point to an endpoint on a network. It is the job of a request to understand the data at the endpoint it is pointing to, and to be able to decode that data into some concrete Swift type. When a ``HTTPRequest`` is submitted through some ``HTTPController``, the ``transform(data:statusCode:using:)`` function is called in order to be able to strongly type the response from the request. This tightly couples the request to the type of content it will provide.
///
/// Implementations should be lightweight, and are intended to be created and recycled quickly.
///
/// A ``HTTPRequest`` only defines ``pathComponents`` and ``queryItems`` and not a full `URL`. This is so that a `URL` can be constructed against some base `URL`, enabling the same request to be submitted against multiple environments, and to remove the opportunity to build a `URL` "stringily".
///
/// Aim to keep any logic that is needed to construct the request in the initialisers.
public protocol HTTPRequest<ResponseType> {

    /// The strongly typed response that this request returns.
    associatedtype ResponseType = Void
    
    /// The object to be encoded to the body of the request.
    associatedtype Body: Encodable = Never

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
    var body: Body? { get }
    
    /// Whether or not the request will require authorization credentials attaching. If so, then ``AuthorizingHTTPController`` and ``ReauthorizingHTTPController`` types will authorize the request before submission.
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    
    /// Transforms the raw `Data` returned over the network into some concrete Swift type.
    ///
    /// It is best practice to check that the `statusCode` is expected before attempting to decode any data. If an unexpected value is encountered, then the `statusCode` can be thrown as an error.
    /// - Parameters:
    ///   - data: The `Data` returned from the network that needs to be decoded.
    ///   - statusCode: The ``HTTPStatusCode`` returned from the network.
    ///   - decoder: A ``DataDecoder`` provided by the calling ``HTTPController`` that can be used to decode the `Data`. This usually has API specific settings such as date decoding options. If the request "knows better" than to use this default decoder, then it should use some other instance.
    /// - Returns: The decoded object.
    /// - Throws: Any errors that occured during decoding. This is most likely to be an unexpeced ``HTTPStatusCode`` or a `DecodingError`.
    func transform(
        data: Data,
        statusCode: HTTPStatusCode,
        using decoder: DataDecoder
    ) throws -> ResponseType
}

public extension HTTPRequest {
    
    var headers: [String : String]? {
        nil
    }
    
    var queryItems: [String : String]? {
        nil
    }
}

public extension HTTPRequest where Body == Never {
    
    var body: Never? {
        nil
    }
}

/*
 swift package --allow-writing-to-directory ./docs generate-documentation --target Networking --disable-indexing --transform-for-static-hosting --hosting-base-path Networking --output-path ./docs
 
  I am NOT figuring this out again!
 */
