//
//  ConfigurationView.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 25/10/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import SwiftUI
import Zone5

// class so that we can pass by reference
class Password {
	var password: String
	init(_ password: String = "") {
		self.password = password
	}
}

struct ConfigurationView: View {

	let apiClient: Zone5
	let userPassword: Password
	
	@State var keyValueStore: KeyValueStore = .shared
	
	@State var boundClientId: String
	@State var boundSecret: String
	@State var boundPassword = Password("")
	@State var boundUserAgent: String

	@Environment(\.presentationMode) var presentationMode

	@State private var pickerIndex = 0

	@State private var isLoading = false

	@State private var error: Zone5.Error? {
		didSet { displayingError = (error != nil) }
	}

	@State private var displayingError = false

	init(apiClient: Zone5 = .shared, keyValueStore: KeyValueStore = .shared, password: Password) {
		self.apiClient = apiClient
		self.userPassword = password
		
		_boundClientId = State(initialValue: keyValueStore.clientID ?? "")
		_boundSecret = State(initialValue: keyValueStore.clientSecret ?? "")
		_boundUserAgent = State(initialValue: keyValueStore.userAgent ?? "")
		
		self.keyValueStore = keyValueStore
	}

	var body: some View {
		NavigationView {
			VStack(alignment: HorizontalAlignment.center, spacing: 0) {
				
				Form {
					Section(header: Text("Base URL"), footer: Text("The URL for the server the SDK should communicate with.")) {
						TextField("Base URL", text: $keyValueStore.baseURLString)
							.textContentType(.URL)
							.keyboardType(.URL)
					}
					
					Section(header: Text("User"), footer: Text("The User to register/log in/delete.")) {
						TextField("User Email", text: $keyValueStore.userEmail)
							.textContentType(.emailAddress)
							.keyboardType(.emailAddress)
					}
					
					Section(header: Text("Password"), footer: Text("Passwod for the User to register/log in/delete.")) {
						TextField("User Password", text: $boundPassword.password)
							.textContentType(.password)
					}
					
					Section(header: Text("User Agent"), footer: Text("String passed with User-Agent header (useful for testing getDeprecated)")) {
						TextField("User Agent", text: $boundUserAgent)
					}

					Section(header: Text("Client Details"), footer: Text("These values are used to identify your application during user authentication.")) {
						TextField("ID", text: $boundClientId)
						TextField("Secret", text: $boundSecret)
					}
				}
				.listStyle(GroupedListStyle())
			}
			.alert(isPresented: $displayingError) {
				let title = Text("An Error Occurred")
				let message = Text(error?.debugDescription ?? "nil")
				return Alert(title: title,
							 message: message,
							 primaryButton: .cancel(),
							 secondaryButton: .default(Text("Try Again"), action: self.configureAndDismiss))
			}
			.navigationBarItems(leading: HStack {
				if apiClient.isConfigured {
					Button(action: dismiss, label: {
						Text("Cancel")
					})
				}
			}, trailing: HStack {
				ActivityIndicator(isAnimating: $isLoading)
				Button(action: configureAndDismiss, label: {
					Text("Save")
				})
			})
			.navigationBarTitle("Configuration", displayMode: .inline)
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}

	func configureAndDismiss() {
		error = nil
		
		if !boundPassword.password.isEmpty {
			self.userPassword.password = boundPassword.password
		}

		keyValueStore.clientSecret = boundSecret
		keyValueStore.clientID = boundClientId
		keyValueStore.userAgent = boundUserAgent
		apiClient.configure(for: keyValueStore.baseURL, clientID: keyValueStore.clientID, clientSecret: keyValueStore.clientSecret, userAgent: keyValueStore.userAgent)
		dismiss()
	}

	func dismiss() {
		self.presentationMode.wrappedValue.dismiss()
	}

}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
		ConfigurationView(password: Password())
    }
}
