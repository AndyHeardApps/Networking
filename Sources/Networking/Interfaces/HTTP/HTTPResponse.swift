
/// Contains the response for a ``HTTPRequest``, wrapping some generic ``content``, a ``statusCode``, and the ``headers``.
///
/// This type is often used to wrap raw `Data` before a ``HTTPRequest`` has decoded it into some more specific type.
public struct HTTPResponse<Content> {
    
    // MARK: - Properties
    
    /// The generic contents of the response.
    public let content: Content
    
    /// The status code returned from the network.
    public let statusCode: HTTPStatusCode
    
    /// The headers of the response.
    public let headers: [AnyHashable : String]
    
    // MARK: - Initialiser
    
    /// Creates a new ``HTTPResponse`` instance.
    public init(
        content: Content,
        statusCode: HTTPStatusCode,
        headers: [AnyHashable : String]
    ) {
        
        self.content = content
        self.statusCode = statusCode
        self.headers = headers
    }
}
