//
//  UpdatedTerms.swift
//  Zone5
//
//  Created by Jean Hall on 9/9/21.
//  Copyright © 2021 Zone5 Ventures. All rights reserved.
//

import Foundation

public struct UpdatedTerms: Codable, JSONEncodedBody {
	public var id: String
	public var name: String?
	public var alias: String?
	public var version: Int?
	public var displayVersion: String?
	public var published: Int?
	public var url: URL?
}
