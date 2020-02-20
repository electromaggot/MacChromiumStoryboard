//
// Authenterface.swift
//	Chromium module
//
// Authentication Interface between Chromium's Browser and Renderer Processes.
//
// Example of bridge between the BROWSE side -- that is, the Application side which
//	can freely(*) access the hard drive, connect out to the network, etc. -- and the
//	locked-down/isolated/sandboxed RENDER side -- which not only renders the web page,
//	receiving user-interactions to on-page controls, but also runs potentially-unsafe
//	javascript, which must not have (*)freedom to access such local resources.
//
// Created by Tadd Jensen on 6/1/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation
import CEFswift


class Authenterface : Encodable {

	static var instance = Authenterface()


	struct RequestData : Encodable {
		var UserName: String?
		var Password: String?
		var SiteName: String?
	}
	public var Request = RequestData()

	struct ResponseData : Encodable {
		var IsAuthenticated: Bool?
		var Token: String?
		var UserRoles: [String]?
	}
	public var Response = ResponseData()


	init() {
	}

	init(request: RequestData) {
		initialize(request: request)
	}

	init(userName: String?, password: String?, siteName: String?) {
		Request.UserName = userName
		Request.Password = password
		Request.SiteName = siteName
	}


	func initialize(request: RequestData) {

		Request.UserName = request.UserName
		Request.Password = request.Password
		Request.SiteName = request.SiteName
	}

	func clearPasswordAsSoonAsUnneeded() {

		Request.Password = nil
	}
	
	func clearAll() {
		
		Request.UserName			= nil
		Request.Password			= nil
		Response.Token				= nil
		Response.UserRoles			= nil
		Response.IsAuthenticated	= nil
	}

	func setAuthentication(didSucceed: Bool, httpAuthToken: String, userRoles: [String]) {

		Response.IsAuthenticated = didSucceed
		Response.Token	   = httpAuthToken
		Response.UserRoles = userRoles
	}
}
