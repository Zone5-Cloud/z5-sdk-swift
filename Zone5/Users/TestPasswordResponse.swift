//
//  TestPasswordResponse.swift
//  Zone5
//
//  Created by Jean Hall on 23/9/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import Foundation

public class TestPasswordResponse: Codable {
	let error: Bool
	var message: String?
	var reason: String?
}
