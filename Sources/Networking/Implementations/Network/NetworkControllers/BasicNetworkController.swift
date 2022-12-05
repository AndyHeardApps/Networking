import Foundation

public struct BasicNetworkController {
    
    // MARK: - Properties
    
    public let baseURL: URL
    
    public let session: NetworkSession
    
    public let decoder: DataDecoder
        
    public let errorHandler: NetworkErrorHandler?

    public let universalHeaders: [String : String]?

    // MARK: - Initialisers

    public init(
        baseURL: URL,
        session: NetworkSession = URLSession.shared,
        decoder: DataDecoder = JSONDecoder(),
        errorHandler: NetworkErrorHandler? = nil,
        universalHeaders: [String : String]? = nil
    ) {
        
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.errorHandler = errorHandler
        self.universalHeaders = universalHeaders
    }
}

// MARK: - Network controller
extension BasicNetworkController: NetworkController {
    
    public func fetchResponse<Request: NetworkRequest>(_ request: Request) async throws -> NetworkResponse<Request.ResponseType> {

        if request.requiresAuthorization {
            throw HTTPStatusCode.unauthorized
        }
        
        let requestWithUniversalHeaders = add(
            universalHeaders: universalHeaders,
            to: request
        )
        
        let dataResponse = try await session.submit(
            request: requestWithUniversalHeaders,
            to: baseURL
        )
        
        do {
            let response = try transform(
                dataResponse: dataResponse,
                from: request,
                using: decoder
            )
            
            return response
                        
        } catch {
            
            guard let errorHandler else {
                throw error
            }
            
            let mappedError = errorHandler.map(
                error,
                from: dataResponse
            )
            
            throw mappedError
        }
    }
}
