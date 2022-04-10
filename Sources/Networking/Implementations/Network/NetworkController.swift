import Foundation

/// The `NetworkController` is what ties all of the network and converting of data together, including authorization. It accepts a `baseURL` which all submitted requests are resolved against using the provided `NetworkSession`. The `JSONDecoder` is handed to all requests to decode any JSON data.
public struct NetworkController<Authorization: AuthorizationProvider> {
    
    // MARK: - Properties
    
    /// The base `URL` that all `NetworkRequest`s are resolved against.
    public let baseURL: URL
    
    /// The `NetworkSession` used to fetch `NetworkResponse`s for `NetworkRequest`s.
    public let session: NetworkSession
    
    /// The `JSONDecoder` used to convert any JSON data in `NetworkRequest`s.
    public let jsonDecoder: JSONDecoder
    
    public let authorization: Authorization
    
    // MARK: - Initialiser
    
    /// Creates a new `NetworkController` instance.
    /// - Parameters:
    ///   - baseURL: The `baseURL` the `NetworkController` uses to resolve requests.
    ///   - session: The `session` the `NetworkController` uses to fetch `Data` for requests.
    ///   - authorization: The `authorization` used to authorize any requests that need it.
    ///   - jsonDecoder: The `jsondDecoder` the `NetworkController` uses to decode JSON data returned by requests.
    public init(baseURL: URL, session: NetworkSession = URLSession.shared, authorization: Authorization, jsonDecoder: JSONDecoder = .init()) {
        
        self.baseURL = baseURL
        self.session = session
        self.authorization = authorization
        self.jsonDecoder = jsonDecoder
    }
}

// MARK: - Submit
extension NetworkController {
    
    /// Submits a `request` and returns only the transformed content of the `request`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: The transformed content of the `request`s endpoint.
    public func fetchContent<Request: NetworkRequest>(_ request: Request) async throws -> Request.ResponseType {
        
        let response = try await fetchResponse(request)
        return response.content
    }
    
    /// Submits a `request` and returns the transformed contents of the `request` alongside the `HTTPStatusCode` and `headers`.
    /// - Parameters:
    ///     - request: The request to be submitted.
    /// - Returns: A `NetworkResponse` containing transformed content of the `request`s endpoint, as well as the `HTTPStatusCode` and `headers` returned.
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {

        do {
            let response = try await fetchAndTransformResponse(for: request)
            extractAuthorizationContent(from: response)
            return response

        } catch HTTPStatusCode.unauthorized {
            guard let reauthorizationRequest = authorization.makeReauthorizationRequest(), !reauthorizationRequest.requiresAuthorization else {
                throw HTTPStatusCode.unauthorized
            }
            let reauthorizationResponse = try await fetchAndTransformResponse(for: reauthorizationRequest)
            extractAuthorizationContent(from: reauthorizationResponse)
            let response = try await fetchAndTransformResponse(for: request)
            return response

        } catch {
            throw error
            
        }
    }

    private func fetchDataResponse<Request: NetworkRequest>(for request: Request) async throws -> NetworkResponse<Data> {
        
        if request.requiresAuthorization {
            let authorizedRequest = authorization.authorize(request)
            return try await session.submit(request: authorizedRequest, to: baseURL)
        }
        
        return try await session.submit(request: request, to: baseURL)
    }
    
    private func fetchAndTransformResponse<Request: NetworkRequest>(for request: Request) async throws -> NetworkResponse<Request.ResponseType> {
        
        let dataResponse = try await fetchDataResponse(for: request)
        
        let transformedContents = try request.transform(
            data: dataResponse.content,
            statusCode: dataResponse.statusCode,
            using: jsonDecoder
        )

        return .init(
            content: transformedContents,
            statusCode: dataResponse.statusCode,
            headers: dataResponse.headers
        )
    }
    
    private func extractAuthorizationContent<Response>(from response: Response) {
        
        if let authorizedResponse = response as? NetworkResponse<Authorization.AuthorizationRequest.ResponseType> {
            authorization.handle(authorizationResponse: authorizedResponse)
        }
        
        if let reauthorizedResponse = response as? NetworkResponse<Authorization.ReauthorizationRequest.ResponseType> {
            authorization.handle(reauthorizationResponse: reauthorizedResponse)
        }
    }
}
