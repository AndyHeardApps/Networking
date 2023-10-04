import Foundation

/// Describes a type that handles errors produced by a ``HTTPController``.
///
/// Implementations of this protocol define a function that accepts an `Error` and the ``HTTPResponse`` containing `Data` that caused the error to be thrown, and attempts to extract more information and map it into a more detailed `Error` type. This gives a developer the opportunity to handle custom error types in the networking logic. Usually the data in in the ``HTTPResponse/content`` will contain further information about the error that can be extracted and returned in a more detailed error type.
public protocol NetworkErrorHandler {
    
    // MARK: - Functions
    
    /// Attempts to map an `Error` and the ``HTTPResponse`` that caused it to be thrown into a more detailed error.
    ///
    /// This function should use the provided `error` and `response` to extract additional information that can explain why the error was thrown, and return an `Error` type containing that information.
    /// - Parameters:
    ///   - error: The error that has been thrown by some request, and needs handling.
    ///   - response: The response that the request produced, potentially containing further details about what went wrong.
    /// - Returns: An error containing as much information on the request failure as possible. As a minium, the provided error should be returned if no more information can be extracted from the response.
    func map(
        _ error: Error,
        from response: HTTPResponse<Data>
    ) -> Error
}
