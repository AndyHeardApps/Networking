import Foundation

/// An abstraction of a network request, this is used by a `NetworkSession` and a `NetworkController` to fetch data from an endpoint. The job of an object implementing the `NetworkRequest` protocol is to point towards an endpoint, and also know what to do with any `Data` and `HTTPStatusCode` returned.
public protocol NetworkRequest<ResponseType> {

    associatedtype ResponseType

    // MARK: - Properties
    
    /// The `HTTPMethod` to use for the request.
    var httpMethod: HTTPMethod { get }
    
    /// The path components for the `URL` of the request. These components are appended to a base `URL` in order. There is no need to insert any `/` in this array.
    var pathComponents: [String] { get }
    
    /// The headers for the request. There is no need to add authorization headers manually if using an `AuthorizingNetworkController`.
    var headers: [String : String]? { get }
    
    /// The query items for the `URL` of the request. These key value pairs are mapped into the `URL` in a random order.
    var queryItems: [String : String]? { get }
    
    /// The body of this request.
    var body: Data? { get }
    
    /// Indicates whether or not this request requires authorization of some sort. If `true` then the `AuthorizingNetworkController` will attempt to provide this request with stored credentials before submitting it.
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    
    /// Transforms the raw data returned from this request into a concrete Swift type. This is usually done by checking the provided `HTTPStatusCode` is an expected one. If so, the `DataDecoder` can be used to decode the data into some type. If the `HTTPStatusCode` is an unexpected one, it can be thrown as an error. This request is used by the `NetworkController` and should not need to be called manually.
    /// - Parameters:
    ///     - data: The raw `Data` returned from the request that needs transforming.
    ///     - statusCode: The `HTTPStatusCode` returned from the request. This can be checked to determine whether or not the request was successful before attempting to manupulate any of the `Data`.
    ///     - decoder: The `DataDecoder` to be used to decode the `Data`. This is provided by the `NetworkController` which can be set up to suit the API being interacted with.
    ///
    /// - Returns: The transformed return type for this request.
    func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> ResponseType
}
