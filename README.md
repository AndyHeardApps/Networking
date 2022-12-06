# Networking

A light-weight, type safe networking libarary for MacOS and iOS projects.

## Usage
```
let authorizationProvider = OAuthAuthorizationProvider<MyAuthorizationRequest, MyReauthorizationRequest>()
let networkController = ReauthorizingNetworkController(
    baseURL: URL(string: "https://www.test.com")!,
    authorization: authorizationProvider
)
let requestRespone = try await networkController.fetchContent(myRequest)
```

For full documentation see the [documentation](https://andyheardapps.github.io)
