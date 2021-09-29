//
//  NewPassword.swift
//  Zone5
//
//  Created by Jean Hall on 2/3/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//

import Foundation

struct NewPassword: JSONEncodedBody {
	var oldPassword: String?
	var newPassword: String
	
	public init(old: String? = nil, new: String) {
		oldPassword = old
		newPassword = new
	}
	
}
