# Networking

A basic networking framework for MacOS and iOS projects.

## Usage

```
let authorizationProvider = OAuthAuthorizationProvider<MyAuthorizationRequest, MyReauthorizationRequest>()
let networkController = NetworkController(
    baseURL: URL(string: "https://www.test.com")!,
    authorization: authorizationProvider
)
let requestRespone = try await networkController.fetchContent(myRequest)
```

## Information

### `NetworkRequest`
`NetworkRequest`s are the basic request for networking. A type implementing this protocol must provide information that points towards an API endpoint such as path and query information. For example:

```
struct SomeRequest: NetworkRequest {

    let httpMethod: HTTPMethod
    let pathComponents: [String]
    let headers: [String : String]?
    let queryItems: [String : String]?
    let body: Data?
    let requiresAuthorization: Bool
}
```

Most endpoints will have a pre-determined `httpMethod` and `pathComponent`s, with `queryItems`, `body` and `headers` being more dynamic and potentially being determined by injected data. For example:

```
init<Body: Encodable>(body: Body) throws {

    self.httpMethod = .post
    self.pathComponents = ["path1", "path2"]
    self.headers = nil
    self.queryItems = ["query" : "value"]
    self.body = try JSONEncoder().encode(body)
    self.requiresAuthorization = false
}
```
The full URL of the request is determined by the `pathComponent`s, `queryItem`s and some `baseURL` that the request doesn't know about, but is provided by a `NetworkController`. The idea is that the same request can be used against both live and test endpoints by using `NetworkController`s with different `baseURL`s.


In addition to pointing towards an API endpoint, the `NetworkRequest` must know how to handle the response from that endpoint and convert it into some Swift type from raw `Data` using the `transform` function.

The type returned from the `transform` function is entirely down to the request, and is determined by the `NetworkRequest`s `ResponseType`.

```
func transform(data: Data, statusCode: HTTPStatusCode, using decoder: JSONDecoder) throws -> SomeDecodable {
        
    switch statusCode {
    case .ok:
        return try decoder.decode(SomeDecodable.self, from: data)
            
    default:
        throw statusCode
            
    }
}
```

Note: - It is good practice to check the provided `statusCode` before attempting to use the `data` so as to avoid trying to decode data that contains error information instead of the desired content. `HTTPStatusCode`s can be thrown as errors if the wrong code is provided.

### `HTTPMethod`
`HTTPMethod` is a type-safe wrapper for the HTTP Methods such as `GET` and `PUT`.

### `HTTPStatusCode`
`HTTPStatusCode` is a wrapper for the standard HTTP status codes such as `200 ok` or `401 unauthorized`. They conform to the `Error` protocol so can be used in pattern matching and thrown if the wrong status code is recieved.

### `NetworkResponse`
`NetworkResponse` is a simple struct containing information returned by a request. It provides some generic `content`, the `HTTPStatusCode` and `headers` returned  by the request.

### `NetworkSession`
`NetworkSession` is a simple protocol with a single function that accepts some `NetworkRequest` and fetches raw `Data` from that endpoint, as well as the `HTTPStatusCode` and `headers` in the form of a `NetworkResponse<Data>`.

Some implementation of this protocol is required by the `NetworkController`. `URLSession` conforms to this protocol, and is the default way in an app to fetch data from the network. However mocking this protocol is useful in testing.

### `AuthorizationProvider`
`AuthorizationProvider` is a type that allows `NetworkController` to perform request authorization and reauthorization. It defines two `NetworkRequest` types. One that is used to authorize the client, and one that is used to reauthorize the client. Reauthorization is optional.

When the `ResponseType` of these requests is returned to a `NetworkController`, the response is handed to the `AuthorizationProvder` to extract any required authorization credentials for use when authorizing future requests.

This authorization is done by the `authorize` function, which accepts some `NetworkController` and uses it to build and return a type-erased `AnyRequest` with whatever authorization credentials that may be required.

When a `NetworkController` encounters a `401 unauthorized` `HTTPStatusCode`, then it will ask for a reauthorization request from the `AuthorizationProvider` using the `makeReauthorizationRequest`. If one is returned, then reauthorization is automatically attempted before retrying the initial failed request. 

**NOTE**: The reauthorization request must return `false` for `requiresAuthorization`.

### `EmptyAuthorizationProvider`
An `AuthorizationProver` that performs no authorization, and is used for non-secure APIs.

### `AuthorizingNetworkController`

A `NetworkController` is what is used to carry out the networking with `NetworkRequest`s. It contains two slightly different functions, both of which accept some `NetworkRequest`, and uses the provided `networkSession` to fetch the response. One returns a full `NetworkResponse` for the request, and the other returns just the `content` for the request.

Both requests on `AuthorizingNetworkController` will perform authorization and reauthorization using the provided `AuthorizationProvider`.

The `JSONDecoder` in the `AuthorizingNetworkController` is provided to all `NetworkRequest` `transform` function calls to allow it to decode JSON data in a consistent manner.
