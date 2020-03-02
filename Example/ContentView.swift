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
			apiClient.configure(for: baseURL, clientID: keyValueStore.clientID, clientSecret: keyValueStore.clientSecret, accessToken: keyValueStore.accessToken)
		}
		else if let accessToken = keyValueStore.accessToken {
			apiClient.configure(for: baseURL, accessToken: accessToken)
		}
	}

	@State var displayConfiguration = false
	
	var newUser = RegisterUser(email: "jean+testingios@todaysplan.com.au", password: "password", firstname: "test", lastname: "person")

	var body: some View {
		NavigationView {
			List {
				Section(header: Text("Zone5"), footer: Text("In order to test the endpoints for the Zone5 API, the app requires configuration of the API URL, and a valid access token.")) {
					Button("Configure Client", action: {
						self.displayConfiguration = true
					})
				}
				Section(header: Text("Users")) {
					EndpointLink<Bool>("Check User Exists") { client, completion in
						client.users.isEmailRegistered(email: self.newUser.email!, completion: completion)
					}
					EndpointLink<Bool>("Reset Password") { client, completion in
						client.users.resetPassword(email: self.newUser.email!, completion: completion)
					}
					EndpointLink<VoidReply>("Change password") { client, completion in
						let newpass = "MyNewP@ssword\(Date().milliseconds)"
						let oldpass = self.keyValueStore.password
						client.users.changePassword(oldPassword: oldpass, newPassword: newpass) { result in
							switch(result) {
							case .success(let r):
								self.keyValueStore.password = newpass
								completion(.success(r))
							case .failure(let error):
								completion(.failure(error))
							}
						}
					}
					EndpointLink("Refresh Token") { client, completion in
						client.users.refreshToken(completion: completion)
					}
					EndpointLink<User>("Me") { client, completion in
						client.users.me { value in
							switch value {
								case .success(let user):
									if let id = user.id, id > 0 {
										self.keyValueStore.userID = id
									}
								
								case .failure(_):
									self.keyValueStore.userID = -1
							}
								
							completion(value)
						}
					}
					EndpointLink<User>("Register New User") { client, completion in
						client.users.register(user: self.newUser) { value in
							switch value {
								case .success(let user):
									if let id = user.id, id > 0 {
										self.keyValueStore.userID = id
										self.keyValueStore.username = self.newUser.email!
										self.keyValueStore.password = self.newUser.password!
									}
								
								case .failure(_):
									self.keyValueStore.userID = -1
							}
								
							completion(value)
						}
					}
					EndpointLink<LoginResponse>("Login") { client, completion in
						let password = self.keyValueStore.password
						let email = self.keyValueStore.username
						client.users.login(email: email, password: password, clientID: self.apiClient.clientID, clientSecret: self.apiClient.clientSecret, completion: completion)
					}
					EndpointLink("Logout") { client, completion in
						client.users.logout(completion: completion)
					}
					EndpointLink<VoidReply>("Delete Account") { client, completion in
						if self.keyValueStore.userID > 0 {
							client.users.deleteAccount(userID: self.keyValueStore.userID, completion: completion)
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
