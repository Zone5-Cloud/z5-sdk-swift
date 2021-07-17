//
//  Roles.swift
//  Zone5
//
//  Created by Jean Hall on 26/2/20.
//  Copyright © 2020 Zone5 Ventures. All rights reserved.
//
import Foundation

public enum Roles: String, Codable {
	/** A normal user / subscriber */
	case user
	
	/** A system administrator */
	case admin
	
	@available(*, deprecated)
	case device
	
	/** user is an event promoter and is associated with an EventCompany */
	case company
	
	/** user is a coach - a coach is someone who has more then one coach/client delegate */
	case coach
	
	/** user has access to beta features */
	case beta
	
	/** User has a premium service */
	case premium
	
	/** Team manager */
	case manager
	
	/** Today's Plan support */
	case support
	
	/** Today's Plan power user */
	case power
	
	/** Component management */
	case components
	
	@available(*, deprecated)
	case tfr
	
	case sky
	
	case doctor
	
	case director
	
	/** Race program access */
	case raceprogram
	
	case audit
	
	case ctm
	
	case stages
	
	case surveys
	
	case teamadmin
	
	case stagesadmin
	
	case beta2
	
	case pi
	
	/** Can manage device serial numbers */
	case deviceadmin
	
	/** Can manage promo codes */
	case promoadmin
	
	case stageslink
	
	case hrv
	
	case reports
	
	case cinch
	
	case alpha
	
	/** Allow users to access old dashboards */
	case olddash
	
	/** Allow user to access the mobile app */
	case app
	
	case routes
	
	/** Advanced coach permission */
	case beta3
	
	/** Specialized R&D projects */
	case specializedresearch
	
	case bora
	
	case quickstep
	
	@available(*, deprecated)
	case bahrain
	
	/** has access to curation tools */
	case curation
	
	/** has access to query for users, request tokens on behalf of users etc */
	case useradmin
}
