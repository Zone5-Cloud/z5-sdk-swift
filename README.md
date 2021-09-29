# Zone5 SDK for Swift

![Unit Test Status](https://github.com/Zone5-Cloud/z5-sdk-swift/workflows/Unit%20Tests/badge.svg)

## Installation

### Swift Package Manager
The most straightforward method of installing the SDK is as a [Swift Package](https://swift.org/package-manager/), which can be done by adding it as a dependency in `Package.swift`, or by following [Apple's documentation on adding package dependencies in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

```swift
import PackageDescription

let package = Package(
    [...]
    dependencies: [
        .package(url: "https://github.com/Zone5-Cloud/z5-sdk-swift.git", from: "1.0.0"),
    ]
)
```

### Carthage
Install the SDK via [Carthage](https://github.com/Carthage/Carthage) by adding the following line to your `Cartfile`:

```
github "Zone5-Cloud/z5-sdk-swift"
```

## Getting Started

Once you've installed the SDK, getting started with using it in your app only takes a handful of steps. Before using it, you'll need to configure it with the OAuth client details used to identify your app to the server:

```swift
import Zone5

let baseURL = URL(string: "https://your-zone5-server.com")!
let clientID = "YOUR-CLIENT-IDENTIFIER"
let clientSecret = "YOUR-CLIENT-SECRET"

// for an unauthenticated session (not yet logged in)
Zone5.shared.configure(for: baseURL, clientID: clientID, clientSecret: clientSecret)

// for persisting a logged in session across App restarts. 
let accessToken: OAuthToken? = <read json OAuthToken from a keystore>
Zone5.shared.configure(for: baseURL, clientID: clientID, clientSecret: clientSecret, accessToken: accessToken)

```

A saved OAuthToken only needs to be passed in at startup. The state of the token is automatically updated on login, logout, accessToken, refreshAccessToken and automatic token refresh.
Token refresh is handled automatically before all authenticated calls and then token updated accordingly.

Whenever the accessToken is updated, either because you called login, logout, accessToken or refreshAccessToken or because of an automatic refresh, the Notification `Zone5.authTokenChangedNotification` is fired on the Zone5 instance with the updated OAuthToken in the userInfo.

Observe this Notification so that you can save the updated Token to persist logged in sessions across App restarts. e.g.

```swift
apiClient.notificationCenter.addObserver(forName: Zone5.authTokenChangedNotification, object: Zone5.shared, queue: nil) { notification in
	let token = notification.userInfo?["accessToken"] as? OAuthToken
	keyValueStore.oauthToken = token
}
```

If there are updated Terms and Conditions identified after a login or refresh, the Notification Zone5.updatedTermsNotification is fired with the list of updated terms in the userInfo. 
Observe this Notification so that you can prompt users to re-accept updated Terms and Conditions. e.g.

```swift		
apiClient.notificationCenter.addObserver(forName: Zone5.updatedTermsNotification, object: Zone5.shared, queue: nil) { notification in
	let terms = notification.userInfo?["updatedTerms"] as? [UpdatedTerms]
	// do something with terms
}
```

Once configured, you'll be able to authenticate users via the methods available through [`Zone5.shared.oAuth and [`Zone5.shared.accessToken`](https://zone5-cloud.github.io/z5-sdk-swift/Classes/OAuthView.html) and [`Zone5.shared.users.login`](https://zone5-cloud.github.io/z5-sdk-swift/Classes/UsersView):

```swift
let username = "EXAMPLE-USERNAME"
let password = "EXAMPLE-PASSWORD"

Zone5.shared.oAuth.accessToken(username: username, password: password) { result in
	switch result {
	case .failure(let error):
		// An error occurred and needs to be handled

	case .success(let accessToken):
		// The user was successfully authenticated. 
		// Your configured accessToken will automatically be updated and the `Zone5.authTokenChangedNotification` Notification will fire
	}
}
```

or

```swift
Zone5.shared.users.login(email: username, password: password, accept: []) { result in
	switch result {
    case .failure(let error):
        // An error occurred and needs to be handled

    case .success(let loginResponse):
        // The user was successfully authenticated. loginResponse contains some user data including roles, identities, updatedTerms etc
        // Your configured accessToken will automatically be updated and the `Zone5.authTokenChangedNotification` Notification will fire
    }
}
```

Once authenticated you can make authenticated calls such as:

```swift
Zone5.shared.users.me { result in
	switch result {
	case .failure(let error):
		// An error occurred and needs to be handled

	case .success(let user):
		// The user's information was successfully retrieved.
	}
}
```

Unauthenticated calls do not require the user to be logged in. These calls include things like Zone5.shared.terms.required, Zone5.shared.users.isEmailRegistered, Zone5.shared.users.register, Zone5.shared.users.resetPassword.

## Unit Tests

Unit tests are included and can be run from both the Swift CLI and via Xcode. There may be some slight differences in how these two sources run tests, so if tests are failing in one, but not the other, this may be the cause. Tests are run automatically on push (of any branch) using the Swift CLI, via a [GitHub Action](https://github.com/Zone5-Cloud/z5-sdk-swift/blob/master/.github/workflows/unit-tests.yml), the result of which can be browsed via [the Actions tab](https://github.com/Zone5-Cloud/z5-sdk-swift/actions?query=workflow%3A%22Unit+Tests%22).

### Running Tests via Swift CLI

Run `swift test` from the repo's root directory. Test results will be logged directly to your terminal window.

### Running Tests via Xcode

In the _Product_ menu, select _Test_, or use the keyboard shortcut—typically &#8984;U. Test results are available from the Test Navigator (&#8984;6). Additional details—such as a coverage report—can be found in the Report Navigator (&#8984;9), by selecting the relevant Test report.

## Documentation
You can [find documentation for this project here](https://zone5-cloud.github.io/z5-sdk-swift/). This documentation is automatically generated with [jazzy](https://github.com/realm/jazzy) from a [GitHub Action](https://github.com/Zone5-Cloud/z5-sdk-swift/blob/master/.github/workflows/documentation.yml) and hosted with [GitHub Pages](https://pages.github.com/).

To generate documentation locally, run `make documentation` or `sh ./scripts/prepare_docs.sh` from the repo's root directory. The output will be generated in the docs folder, and should _not_ be included with commits (as the online documentation is automatically generated and updated).
