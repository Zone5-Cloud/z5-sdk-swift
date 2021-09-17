//
//  ContentView.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 8/10/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import SwiftUI
import Zone5

private class Endpoint: RequestEndpoint {
    var url: URL?
    var uri: String
    var requiresAccessToken: Bool

    init(_ endpoint: RequestEndpoint, replace: String, with: String) {
        requiresAccessToken = true
        uri = endpoint.uri.replacingOccurrences(of: "{\(replace)}", with: with)
        url = URL(string: uri)
    }
}

private enum ExternalEndpoints: String, InternalRequestEndpoint, RequestEndpoint {
    case download = "https://api-sp-staging.todaysplan.com.au/rest/files/download/{fileID}"
    case downloadNonZone5 = "https://developer.apple.com/augmented-reality/quick-look/models/gramophone/gramophone.usdz"
    case me = "https://api-sp-staging.todaysplan.com.au/rest/users/me"
    case upload = "https://api-sp-staging.todaysplan.com.au/rest/files/upload"

    func tokenized(replace: String, with: String) -> RequestEndpoint {
        return Endpoint(self, replace: replace, with: with)
    }
}

struct ContentView: View {

    let apiClient: Zone5
    let password: Password = Password()
    let keyValueStore: KeyValueStore

    @State var displayConfiguration = false
    @State var metric: UnitMeasurement = .metric
    @State var me: User = User() // currently logged in user
    @State var lastRegisteredId: Int? // last registered user, this is also who you can delete
    @State var isEbike: Bool = false

    init(apiClient: Zone5 = .shared, keyValueStore: KeyValueStore = .shared) {
        self.apiClient = apiClient
        self.keyValueStore = keyValueStore
        apiClient.debugLogging = true

		apiClient.configure(for: keyValueStore.baseURL, clientID: keyValueStore.clientID, clientSecret: keyValueStore.clientSecret, userAgent: keyValueStore.userAgent, accessToken: keyValueStore.oauthToken)
		
        apiClient.notificationCenter.addObserver(forName: Zone5.authTokenChangedNotification, object: apiClient, queue: nil) { notification in
            let token = notification.userInfo?["accessToken"] as? OAuthToken
            keyValueStore.oauthToken = token
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Zone5"), footer: Text("In order to test the endpoints for the Zone5 API, the app requires configuration of the API URL, and a valid access token.")) {
                    Button("Configure Client", action: {
                        self.displayConfiguration = true
                    })
                }
                Section(header: Text("Users")) {
                    EndpointLink<UsersPreferences>("Get user preferences") { client, completion in
                        if let id = self.me.id {
                            client.users.getPreferences(userID: id) { value in
                                switch value {
                                case .success(let prefs):
                                    if let metric = prefs.metric, metric == .metric {
                                        self.metric = .imperial
                                    }
                                    else {
                                        self.metric = .metric
                                    }
                                    completion(value)
                                case .failure(_):
                                    completion(value)
                                }
                            }
                        } else {
                            completion(.failure(.invalidConfiguration))
                        }
                    }
                    EndpointLink<Bool>("Set User Preferences") { client, completion in
                        if let _ = self.me.id {
                            var prefs = UsersPreferences()
                            prefs.metric = self.metric
                            client.users.setPreferences(preferences: prefs, completion: completion)
                        } else {
                            completion(.failure(.invalidConfiguration))
                        }
                    }
                    EndpointLink<Bool>("Check User Exists") { client, completion in
                        client.users.isEmailRegistered(email: keyValueStore.userEmail, completion: completion)
                    }
                    EndpointLink<User>("Me") { client, completion in
                        client.users.me { value in
                            switch value {
                            case .success(let user):
                                if let id = user.id, id > 0 {
                                    self.me.id = id
                                }

                            case .failure(_):
                                print("Not logged in")
                            }

                            completion(value)
                        }
                    }
                    EndpointLink<User>("Me EXTERNAL") { client, completion in
                        client.external.requestDecode(ExternalEndpoints.me, method: .get, completion: completion)
                    }
                    EndpointLink<Bool>("Update User Name") { client, completion in
                        me.firstName = "first\(Date().timeIntervalSince1970)"
                        me.lastName = "last\(Date().timeIntervalSince1970)"
                        client.users.updateUser(user: me, completion: completion)
                    }
                    EndpointLink<[String:Bool]>("Check Email Status") { client, completion in
                        client.users.getEmailValidationStatus(email: keyValueStore.userEmail, completion: completion)
                    }
                    EndpointLink<User>("Register New User") { client, completion in
                        let email = keyValueStore.userEmail
                        let password = self.password.password
                        let firstname = "test"
                        let lastname = "person"
                        if !email.isEmpty, !password.isEmpty {
                            var registerUser = RegisterUser(email: email, password: password, firstname: firstname, lastname: lastname)
                            registerUser.units = UnitMeasurement.imperial
                            client.users.register(user: registerUser) { value in
                                switch value {
                                case .success(let user):
                                    if let id = user.id, id > 0 {
                                        self.lastRegisteredId = id
                                    }

                                case .failure(_):
                                    print("failed to create new user")
                                }

                                completion(value)
                            }
                        } else {
                            completion(.failure(.invalidConfiguration))
                        }
                    }
                    EndpointLink<Zone5.VoidReply>("Delete last registered Account (if any)") { client, completion in
                        if let id = self.lastRegisteredId {
                            client.users.deleteAccount(userID: id, completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
                Section(header: Text("Auth"), footer: Text("Note that Register New User may requires a second auth step of going to the email for the user and clicking confirm email - depends on Cognito Client Key configuration")) {
                    EndpointLink<Bool>("Reset Password") { client, completion in
                        client.users.resetPassword(email: keyValueStore.userEmail, completion: completion)
                    }
                    EndpointLink<Zone5.VoidReply>("Change password") { client, completion in
                        if let oldpass = self.me.password {
                            let newpass = "MyNewP@ssword\(Date().milliseconds)"
                            client.users.changePassword(oldPassword: oldpass, newPassword: newpass) { result in
                                switch(result) {
                                case .success(let r):
                                    self.password.password = newpass
                                    self.me.password = newpass
                                    completion(.success(r))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        } else {
                            completion(.failure(.invalidConfiguration))
                        }
                    }
                    EndpointLink<OAuthTokenAlt>("Refresh Gigya Token") { client, completion in
                        client.users.refreshToken(completion: completion)
                    }
                    EndpointLink<OAuthToken>("Refresh Cognito Token") { client, completion in
                        client.oAuth.refreshAccessToken(username: keyValueStore.userEmail, completion: completion)
                    }
                    EndpointLink<LoginResponse>("Login") { client, completion in
                        let userPassword: String = self.password.password
                        client.users.login(email: keyValueStore.userEmail, password: userPassword, clientID: self.apiClient.clientID, clientSecret: self.apiClient.clientSecret, accept: ["Specialized_Terms_Apps", "Specialized_Terms"]) { value in
                            switch(value) {
                            case .success(let response):
                                if let user = response.user, let id = user.id, id > 0 {
                                    self.me.id = id
                                }
                            case .failure(_):
                                print("failed to log in")
                            }
                            completion(value)
                        }
                    }
                    EndpointLink("Logout") { client, completion in
                        client.users.logout(completion: completion)
                    }
                    EndpointLink<OAuthToken>("Get Access Token") { client, completion in
                        client.oAuth.accessToken(username: keyValueStore.userEmail, password: self.password.password, completion: completion)
                    }
                    EndpointLink<OAuthToken>("Get Adhoc Access Token") { client, completion in
                        client.oAuth.adhocAccessToken(for: "wahooride", completion: completion)
                    }
                    EndpointLink<Zone5.VoidReply>("Resend email confirmation") { client, completion in
                        let email = keyValueStore.userEmail
                        if !email.isEmpty {
                            client.users.reconfirmEmail(email: email, completion: completion)
                        } else {
                            completion(.failure(.invalidConfiguration))
                        }
                    }
                    EndpointLink<String>("Get Password Complexity Regex") { client, completion in
                        client.users.passwordComplexity(completion: completion)
                    }
                }
                Section(header: Text("Activities"), footer: Text("Attempting to view \"Next Page\" before performing a legitimate search request—such as by opening the \"Last 30 days\" screen—will return an empty result.")) {
                    EndpointLink<SearchResult<UserWorkoutResult>>("Last 3 days") { client, completion in
                        var criteria = UserWorkoutFileSearch()
                        criteria.dateRanges = [DateRange(component: .month, value: 1, starting: .now - (1000 * 60 * 60 * 24 * 3))!]
                        criteria.order = [.descending("ts")]

                        var parameters = SearchInput(criteria: criteria)
                        parameters.fields = UserWorkoutResult.fields()
                        parameters.fields += UserWorkoutResultTurboExt.fields(prefix: "turboExt")
                        parameters.fields += UserWorkoutResultBike.fields(prefix: "bike")
                        parameters.fields += UserWorkoutResultTurbo.fields(prefix: "turbo")

                        client.activities.search(parameters, offset: 0, count: 10, completion: completion)
                    }
                    EndpointLink("Next Page") { client, completion in
                        client.activities.next(offset: 10, count: 10, completion: completion)
                    }
                    EndpointLink<Bool>("Set Bike") { client, completion in
                        // change activity.id and bike.bikeUuid to set desired association. The below is a past ride and bike
                        // for jean+turbo on Specialized Staging
                        client.activities.setBike(type: .file, id: 120647, bikeID: "01cf97af-880b-4869-bf36-a7d7e438203d", completion: completion)
                    }
                    EndpointLink<Bool>("toggle eBike") { client, completion in
                        client.activities.setIsEbike(type: .file, id: 12007901, isEbike: isEbike, completion: completion)
                        isEbike = !isEbike
                    }
                    EndpointLink<MappedResult<UserWorkoutResult>>("Search by Bike") { client, completion in
                        // andrew's sepcialized staging bike.
                        let bikeIDAndrewStaging = "d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c"
                        // jean's Specialized prod bikes
                        let bikeIDJean1Prod = "7aaf952e-e213-42c3-aee7-e4231fdb1ff4"
                        let bikeIDJean2Prod = "71fea48c-a1c4-4477-b5f4-cbc313420f9c"
                        // jean+turbo's Specialized staging bikes
                        let bikeIDJean1Staging = "eaa6a925-9e6e-4121-ab35-d04381f51ff4" // bikeUUid
                        // jean+turbo's prod bike
                        let bikeIDJean3Prod = "389994ba-464e-4bdd-b24e-cdb0172a6f28"
                        let dates = DateRange(name: "last 60 days", floor: Date(Date().timeIntervalSince1970.milliseconds - (60*24*60*60*1000)), ceiling: Date() + 10)
                        var fields: [String] = ["sum.distance","sum.elapsed","bike.uuid","max.turbo.numAssistChanges"]
                        fields += UserWorkoutResultTurbo.fields(prefix: "max.turbo")
                        fields += UserWorkoutResultTurbo.fields(prefix: "min.turbo")
                        fields += UserWorkoutResultTurbo.fields(prefix: "sum.turbo")
                        fields += UserWorkoutResultTurbo.fields(prefix: "avg.turbo")
                        fields += UserWorkoutResultTurboExt.fields(prefix: "avg.turboExt")
                        fields += UserWorkoutResultTurboExt.fields(prefix: "max.turboExt")
                        fields += UserWorkoutResultTurboExt.fields(prefix: "min.turboExt")
                        fields += UserWorkoutResultTurboExt.fields(prefix: "sum.turboExt")

                        client.metrics.getBikeMetrics(ranges: [dates], fields: fields, bikeUids: [bikeIDJean1Prod, bikeIDJean2Prod, bikeIDJean3Prod, bikeIDJean1Staging, bikeIDAndrewStaging], completion: completion)
                    }
                }
                Section {
                    EndpointLink<DataFileUploadIndex>("Upload File") { client, completion in
                        guard let fileURL = Bundle.main.url(forDevelopmentAsset: "2013-12-22-10-30-12", withExtension: "fit") else {
                            completion(.failure(.unknown))

                            return
                        }

                        var context = DataFileUploadContext()
                        context.equipment = .gravel
                        context.name = "Epic Ride"
                        //context.bikeID = bikeIDJean1Staging

                        client.activities.upload(fileURL, context: context) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let index):
                                self.checkUploadStatus(client, index: index, completion: completion)
                            }
                        }
                    }
                    EndpointLink<DataFileUploadIndex>("Upload File EXTERNAL") { client, completion in
                        guard let fileURL = Bundle.main.url(forDevelopmentAsset: "2013-12-22-10-30-12", withExtension: "fit") else {
                            completion(.failure(.unknown))

                            return
                        }

                        var context = DataFileUploadContext()
                        context.equipment = .gravel
                        context.name = "Epic Ride"
                        context.startTime = .now
                        //context.bikeID = "d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c"

                        client.external.postUpload(ExternalEndpoints.upload, file: fileURL, body: context, type: DataFileUploadIndex.self) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let index):
                                self.checkUploadStatus(client, index: index, completion: completion)
                            }
                        }
                    }
                    EndpointLink<URL>("Download Latest File") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.activities.downloadOriginal(activity.fileID!, completion: completion)
                            }
                        }
                    }
                    EndpointLink<URL>("Download Latest File EXTERNAL") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.external.download(ExternalEndpoints.download.tokenized(replace: "fileID", with: "\(activity.fileID!)"), headers: ["tp-nodecorate":"true"], progressHandler: { bytes, totalBytes, expectedBytes in
                                    print("progress: bytes: \(bytes), total bytes: \(totalBytes), expected bytes: \(expectedBytes)")
                                }, completionHandler: { result in
                                    print("download complete")
                                    completion(result)
                                })
                            }
                        }
                    }
                    EndpointLink<URL>("Download file from Apple EXTERNAL") { client, completion in
                        client.external.download(ExternalEndpoints.downloadNonZone5, progressHandler: { bytes, totalBytes, expectedBytes in
                            print("progress: bytes: \(bytes), total bytes: \(totalBytes), expected bytes: \(expectedBytes)")
                        }, completionHandler: { result in
                            print("download complete")
                            completion(result)
                        })
                    }
                    EndpointLink<URL>("Download Latest File as Raw3") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.activities.downloadRaw(activity.fileID!) { result in
                                    completion(result)
                                }
                            }
                        }
                    }
                    EndpointLink<URL>("Download Latest File as CSV") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.activities.downloadCSV(activity.fileID!) { result in
                                    completion(result)
                                }
                            }
                        }
                    }
                    EndpointLink<URL>("Download Latest File as Map") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.activities.downloadMap(activity.fileID!) { result in
                                    completion(result)
                                }
                            }
                        }
                    }
                    EndpointLink<Bool>("Delete Latest File") { client, completion in
                        self.retrieveFileIdentifier(client) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))

                            case .success(let activity):
                                client.activities.delete(type: activity.activity!, id: activity.id!, completion: completion)
                            }
                        }
                    }
                }
				Section(header: Text("Third Party Connections"), footer: Text("")) {
					EndpointLink<String>("Pair Wahoo Connection") { client, completion in
						client.thirdPartyConnections.pairThirdPartyConnection(type: .wahoo, redirect: URL(string: "zone5Example://zone5Example.zone5cloud.com")!) { result in
							if case .success(let r) = result, let url = URL(string: r) {
								DispatchQueue.main.async {
									if UIApplication.shared.canOpenURL(url) {
										UIApplication.shared.open(url)
									}
								}
							}
							completion(result)
						}
					}
					EndpointLink<String>("Pair Garmin Connection") { client, completion in
						client.thirdPartyConnections.pairThirdPartyConnection(type: .garminconnect, redirect: URL(string: "zone5Example://zone5Example.zone5cloud.com")!) { result in
							if case .success(let r) = result, let url = URL(string: r) {
								DispatchQueue.main.async {
									if UIApplication.shared.canOpenURL(url) {
										UIApplication.shared.open(url)
									}
								}
							}
							completion(result)
						}
					}
					EndpointLink<String>("Pair Strava Connection") { client, completion in
						client.thirdPartyConnections.pairThirdPartyConnection(type: .strava, redirect: URL(string: "zone5Example://zone5Example.zone5cloud.com")!) { result in
							if case .success(let r) = result, let url = URL(string: r) {
								DispatchQueue.main.async {
									if UIApplication.shared.canOpenURL(url) {
										UIApplication.shared.open(url)
									}
								}
							}
							completion(result)
						}
					}
					EndpointLink<String>("Pair Garmin TrainingConnection") { client, completion in
						client.thirdPartyConnections.pairThirdPartyConnection(type: .garmintraining, redirect: URL(string: "zone5Example://zone5Example.zone5cloud.com")!) { result in
							if case .success(let r) = result, let url = URL(string: r) {
								DispatchQueue.main.async {
									if UIApplication.shared.canOpenURL(url) {
										UIApplication.shared.open(url)
									}
								}
							}
							completion(result)
						}
					}
					EndpointLink<Bool>("Has Wahoo Connection") { client, completion in
						client.thirdPartyConnections.hasThirdPartyToken(type: .wahoo, completion: completion)
					}
					EndpointLink<Bool>("Has Garmin Connection") { client, completion in
						client.thirdPartyConnections.hasThirdPartyToken(type: .garminconnect, completion: completion)
					}
					EndpointLink<Bool>("Has Strava Connection") { client, completion in
						client.thirdPartyConnections.hasThirdPartyToken(type: .strava, completion: completion)
					}
					EndpointLink<Bool>("Has Garmin Training Connection") { client, completion in
						client.thirdPartyConnections.hasThirdPartyToken(type: .garmintraining, completion: completion)
					}
					EndpointLink<Bool>("Remove All Connectiona") { client, completion in
						client.thirdPartyConnections.removeThirdPartyToken(type: .wahoo, completion: completion)
						client.thirdPartyConnections.removeThirdPartyToken(type: .garminconnect, completion: completion)
						client.thirdPartyConnections.removeThirdPartyToken(type: .strava, completion: completion)
						client.thirdPartyConnections.removeThirdPartyToken(type: .garmintraining, completion: completion)
					}
				}
				Section(header: Text("Push Registration")) {
					EndpointLink<PushRegistrationResponse>("Register Device") { client, completion in
						let rego = PushRegistration(token: "1234", platform: "strava", deviceId: "gwjh4")
						client.thirdPartyConnections.registerDeviceWithThirdParty(registration: rego, completion: completion)
					}
					EndpointLink<Zone5.VoidReply>("Deregister Device") { client, completion in
						client.thirdPartyConnections.deregisterDeviceWithThirdParty(token: "1234", completion: completion)
					}
				}
                Section(header: Text("User Agent Queries")) {
                    EndpointLink<UpgradeAvailableResponse>("Is upgrade available") { client, completion in
                        client.userAgents.getDeprecated(completion: completion)
                    }
                }
                Section(header: Text("In App Purchases")) {
                    EndpointLink<Products>("List Products") { client, completion in
                        client.payments.products(for: "tp-app", completion: completion)
                    }
                    EndpointLink<PaymentVerification>("verify") { client, completion in
                        let receipt = PaymentVerification(provider: "apple", data: "asd", productDescr: "asdf", currencyCode: "au", cost: 3)
                        client.payments.verify(for: "tp-app", with: receipt, completion: completion)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Zone5 Example")
        }
        .sheet(isPresented: $displayConfiguration) {
            ConfigurationView(apiClient: self.apiClient, keyValueStore: self.keyValueStore, password: self.password)
        }
        .onAppear {
            if !self.apiClient.isConfigured  {
                self.displayConfiguration = true
            }
        }
    }

    private func checkUploadStatus(_ client: Zone5, index: DataFileUploadIndex, completion: @escaping (_ result: Result<DataFileUploadIndex, Zone5.Error>) -> Void) {
        completion(.success(index))

        sleep(1)

        switch index.state {
        case .finished, .error:
            break

        default:
            client.activities.uploadStatus(of: index.id) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))

                case .success(let index):
                    self.checkUploadStatus(client, index: index, completion: completion)
                }
            }
        }
    }

    private func retrieveFileIdentifier(_ client: Zone5, _ completion: @escaping (_ result: Result<UserWorkoutResult, Zone5.Error>) -> Void) {
        var criteria = UserWorkoutFileSearch()
        //criteria.name = "2013-12-22-10-30-12.fit"
        criteria.dateRanges = [DateRange(component: .month, value: -3)!]
        criteria.order = [.descending("ts")]

        let parameters = SearchInput(criteria: criteria)

        client.activities.search(parameters, offset: 0, count: 1) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let response):
                guard let activity = response.first, activity.fileID != nil else {
                    completion(.failure(.unknown))

                    return
                }

                completion(.success(activity))
            }
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
