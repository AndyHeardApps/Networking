# Networking

A light-weight, type safe networking libarary for MacOS and iOS projects.

- Perform decoding inline.
- Authorization and reauthorization available automatically.
- Type safe requests and responses.
- Custom error handling.
- OAuth types built in.

## Usage
```
let authorizationProvider = OAuthAuthorizationProvider<MyAuthorizationRequest, MyReauthorizationRequest>()
let networkController = ReauthorizingNetworkController(
    baseURL: URL(string: "https://www.test.com")!,
    authorization: authorizationProvider
)
let requestRespone = try await networkController.fetchContent(myRequest)
```

Full documentation available [here](https://andyheardapps.github.io/Networking/documentation/networking). Specifically [`BasicNetworkController`](https://andyheardapps.github.io/Networking/documentation/networking/basicnetworkcontroller) and [`NetworkRequest`](https://andyheardapps.github.io/Networking/documentation/networking/networkrequest).
