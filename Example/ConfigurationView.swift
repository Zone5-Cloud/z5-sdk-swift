//
//  ConfigurationView.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 25/10/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import SwiftUI
import Zone5

struct ConfigurationView: View {

	let apiClient: Zone5

	@State var keyValueStore: KeyValueStore = .shared

	@Environment(\.presentationMode) var presentationMode

	@State private var pickerIndex = 0

	@State private var isLoading = false

	@State private var error: Zone5.Error? {
		didSet { displayingError = (error != nil) }
	}

	@State private var displayingError = false

	init(apiClient: Zone5 = .shared, keyValueStore: KeyValueStore = .shared) {
		self.apiClient = apiClient
		self.keyValueStore = keyValueStore
	}

	var body: some View {
		NavigationView {
			VStack(alignment: HorizontalAlignment.center, spacing: 0) {
				Picker("Boop", selection: $pickerIndex) {
					Text("OAuth Client").tag(0)
					Text("GIGYA").tag(1)
				}
				.pickerStyle(SegmentedPickerStyle())
				.padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
				.background(Color(.systemGroupedBackground))

				Form {
					Section(header: Text("Base URL"), footer: Text("The URL for the server the SDK should communicate with.")) {
						TextField("Base URL", text: $keyValueStore.baseURLString)
							.textContentType(.URL)
							.keyboardType(.URL)
					}

					if self.pickerIndex == 0 {
						Section(header: Text("Client Details"), footer: Text("These values are used to identify your application during user authentication.")) {
							TextField("ID", text: $keyValueStore.clientID)
							TextField("Secret", text: $keyValueStore.clientSecret)
						}
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

		// There are two ways to prepare your client for accessing the Zone5 API. If you are using Specialized Staging or Prod
		// then no clientID or clientSecret are required as all auth goes through GIGYA.
		//
		// Otherwise, you'll need to first configure your application with a valid `clientID` and `clientSecret` before
		// then authenticating the user to retrieve an access token.
		if pickerIndex == 0 {
			// First we'll configure our client using the `baseURL`, `clientID` and `clientSecret` entered via the UI.
			// These values would normally be embedded in your application and thus hidden from the user, as they
			// identify your application.
			apiClient.configure(for: keyValueStore.baseURL, clientID: keyValueStore.clientID, clientSecret: keyValueStore.clientSecret)
			self.dismiss()
		} else if pickerIndex == 1 {
			apiClient.configure(for: keyValueStore.baseURL)
			self.dismiss()
		}
		else {
			error = .invalidConfiguration
		}
	}

	func dismiss() {
		self.presentationMode.wrappedValue.dismiss()
	}

}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
    }
}
