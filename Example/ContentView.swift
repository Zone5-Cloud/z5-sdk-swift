//
//  ContentView.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 8/10/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import SwiftUI
import Zone5

struct ContentView: View {

	let apiClient: Zone5

	@State var keyValueStore: KeyValueStore = .shared
	@State var displayConfiguration = false
	@State var metric: UnitMeasurement = .metric
	@State var newUser: User = User(email: "insert-email-here", password: "ComplexP@55word", firstname: "test", lastname: "person")
	@State var me: User = User()

	init(apiClient: Zone5 = .shared, keyValueStore: KeyValueStore = .shared) {
		self.apiClient = apiClient
		self.keyValueStore = keyValueStore

		// Do not use UserDefaults for storing user credentials in a production application. It is incredibly insecure,
		// and a terrible idea. Don't do it.
		//
		// If you have stored your AccessToken (nice and securely), you can quite easily configure the SDK to use that
		// at any point, and completely bypass configuring the clientID and clientSecret, which are only used as part of
		// the user authentication process.
		let baseURL = keyValueStore.baseURL
		if !keyValueStore.clientID.isEmpty, !keyValueStore.clientSecret.isEmpty {
			apiClient.configure(for: baseURL, clientID: keyValueStore.clientID, clientSecret: keyValueStore.clientSecret)
		}
		else {
			apiClient.configure(for: baseURL)
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
							completion(.failure(.requiresAccessToken))
						}
					}
					EndpointLink<Bool>("Set User Preferences") { client, completion in
						if let _ = self.me.id {
							var prefs = UsersPreferences()
							prefs.metric = self.metric
							client.users.setPreferences(preferences: prefs, completion: completion)
						} else {
							completion(.failure(.requiresAccessToken))
						}
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
				}
				Section(header: Text("Auth"), footer: Text("Note that Register New User on TP servers makes an immediately usable user but on Specialized servers it requires a second auth step of going to the email for the user and clicking confirm email")) {
					EndpointLink<Bool>("Check User Exists") { client, completion in
						client.users.isEmailRegistered(email: self.newUser.email!, completion: completion)
					}
					EndpointLink<[String:Bool]>("Check Email Status") { client, completion in
						if let email = self.newUser.email {
							client.users.getEmailValidationStatus(email: email, completion: completion)
						}
					}
					EndpointLink<Bool>("Reset Password") { client, completion in
						client.users.resetPassword(email: self.newUser.email!, completion: completion)
					}
					EndpointLink<VoidReply>("Change password") { client, completion in
						if let oldpass = self.me.password {
							let newpass = "MyNewP@ssword\(Date().milliseconds)"
							client.users.changePassword(oldPassword: oldpass, newPassword: newpass) { result in
								switch(result) {
								case .success(let r):
									self.newUser.password = newpass
									self.me.password = newpass
									completion(.success(r))
								case .failure(let error):
									completion(.failure(error))
								}
							}
						} else {
							completion(.failure(.requiresAccessToken))
						}
					}
					EndpointLink("Refresh Token") { client, completion in
						client.users.refreshToken(completion: completion)
					}
					EndpointLink<User>("Register New User") { client, completion in
						if let email = self.newUser.email, let password = self.newUser.password, let firstname = self.newUser.firstName, let lastname = self.newUser.lastName {
							var registerUser = RegisterUser(email: email, password: password, firstname: firstname, lastname: lastname)
							registerUser.units = UnitMeasurement.imperial
							client.users.register(user: registerUser) { value in
								switch value {
									case .success(let user):
										if let id = user.id, id > 0 {
											self.newUser.id = id
										}
									
									case .failure(_):
										print("failed to create new user")
								}
									
								completion(value)
							}
						} else {
							completion(.failure(.unknown))
						}
					}
					EndpointLink<LoginResponse>("Login") { client, completion in
						let password = self.newUser.password
						let email = self.newUser.email
						client.users.login(email: email!, password: password!, clientID: self.apiClient.clientID, clientSecret: self.apiClient.clientSecret) { value in
							switch(value) {
								case .success(let response):
									if let user = response.user, let id = user.id, id > 0 {
										self.me.id = id
										self.newUser.id = id
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
					EndpointLink<VoidReply>("Delete Account") { client, completion in
						if let id = self.newUser.id {
							client.users.deleteAccount(userID: id, completion: completion)
						} else {
							completion(.failure(.unknown))
						}
					}
				}
				Section(header: Text("Activities"), footer: Text("Attempting to view \"Next Page\" before performing a legitimate search request—such as by opening the \"Next 3 Months\" screen—will return an empty result.")) {
					EndpointLink<SearchResult<UserWorkoutResult>>("Next 3 Months") { client, completion in
						var criteria = UserWorkoutFileSearch()
						criteria.dateRanges = [DateRange(component: .month, value: 3)!]
						criteria.order = [.ascending("ts")]

						var parameters = SearchInput(criteria: criteria)
						parameters.fields = ["name", "distance", "ascent", "peak3minWatts", "peak20minWatts", "channels", "bike.serial", "bike.name", "bike.uuid", "bike.avatar", "bike.descr"]

						client.activities.search(parameters, offset: 0, count: 10, completion: completion)
					}
					EndpointLink("Next Page") { client, completion in
						client.activities.next(offset: 10, count: 10, completion: completion)
					}
					EndpointLink<MappedResult<UserWorkoutResult>>("Search by Bike") { client, completion in
						let bikeID = "d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c" // andrew's bike. Only works on sepcialized servers
						let dates = DateRange(name: "last 10 days", floor: Date().timeIntervalSince1970.milliseconds - (10*24*60*60*1000), ceiling: Date().timeIntervalSince1970.milliseconds)
						client.metrics.getBikeMetrics(ranges: [dates], fields: ["sum.training","sum.distance","sum.ascent","wavg.avgSpeed","max.maxSpeed","wavg.avgWatts","max.maxWatts"], bikeUids: [bikeID], completion: completion)
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
						context.startTime = .now
						//context.bikeID = "d584c5cb-e81f-4fbe-bc0d-667e9bcd2c4c"

						client.activities.upload(fileURL, context: context) { result in
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
								client.activities.downloadOriginal(activity.fileID!) { result in
									completion(result)
								}
							}
						}
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
			}
			.listStyle(GroupedListStyle())
			.navigationBarTitle("Zone5 Example")
		}
		.sheet(isPresented: $displayConfiguration) {
			ConfigurationView(apiClient: self.apiClient, keyValueStore: self.keyValueStore)
		}
		.onAppear {
			if !self.apiClient.isConfigured {
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
		criteria.name = "2013-12-22-10-30-12.fit"
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
