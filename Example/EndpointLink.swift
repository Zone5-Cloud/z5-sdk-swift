//
//  EndpointLink.swift
//  Zone5 Example
//
//  Created by Daniel Farrelly on 25/10/19.
//  Copyright © 2019 Zone5 Ventures. All rights reserved.
//

import SwiftUI
import Zone5

protocol AnyParameter: AnyObject {

}

class Parameter<Value>: AnyParameter {

	var label: String

	var value: Value?

	init(label: String) {
		self.label = label
	}

}

struct EndpointLink<Response>: View {

	let title: String

	@ObservedObject var controller: EndpointController<Response>

	init(_ title: String, controller: EndpointController<Response>) {
		self.title = title
		self.controller = controller
	}

	init(_ title: String, apiClient: Zone5 = .shared, handler: @escaping EndpointController<Response>.Handler) {
		self.init(title, controller: EndpointController(apiClient: apiClient, handler: handler))
	}

	var body: some View {
		return NavigationLink(destination: EndpointView<Response>(title, controller: controller)) {
			HStack {
				Text(title)
				Spacer()
				ActivityIndicator(isAnimating: $controller.isLoading)
			}
		}
	}

}

struct EndpointLink_Previews: PreviewProvider {
    static var previews: some View {
		Form {
			EndpointLink<User>("User") { _, completion in
				var user = User()
				user.id = 12345
				user.email = "jane.smith@example.com"
				user.firstName = "Jane"
				user.lastName = "Smith"

				completion(.success(user))
			}
		}
    }
}

