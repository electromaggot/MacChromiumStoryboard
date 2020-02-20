//
// cefV8ObjectBuilder.swift
//	RenderProcess, ChromiumHelper
//
// Some render-process-specific app-specific CEF V8 object handling.
// This file can probably be deprecated/eliminated soon, but it
//	does provide some assistance in testing and sanity checking
//	of the generation of those objects.
//
// Cleaved by Tadd Jensen on 9/20/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation
import CEFswift


extension JSHandler {

	// Test out code to procedurally generate a CEF V8 object, comparing it to a manually built object.
	/* temporary */ private func workInProgressTest() {		//	...although none of this is used any longer,
															//	since the Angular side of the GUI takes JSON now.
		if let obj = authenticationDataAsCEFV8Object() {
			DumpCEFV8(object: obj, name: "autoAuthenticationData")
		}
		if let obj = authenticationDataAsManuallyCreatedCEFV8Object() {
			DumpCEFV8(object: obj, name: "manualAuthenticationData")
		}
	}
	private func authenticationDataAsCEFV8Object() -> CEFV8Value? {

		return CreateExampleCEFV8Object(from: Authenterface.instance)
	}

	// V8 Object specific to demoApp Authentication.
	//
	private func authenticationDataAsManuallyCreatedCEFV8Object() -> CEFV8Value? {

		// Manually construct CEFV8Value object/hierarchy in this vein:
		//	ExampleAuth:
		//		Request: ExampleRequest
		//		Response: ExampleResponse
		//	ExampleRequest:
		//		UserName: string
		//		Password: string
		//		SiteName: string
		//	ExampleResponse:
		//		IsAuthenticated: boolean
		//		Token: string
		//		UserRoles: string[]

		let auth = Authenterface.instance

		if let ExampleAuth = CEFV8Value.createObject(),
		   let xmplRequest = CEFV8Value.createObject(),
		   let xmplResponse = CEFV8Value.createObject() {

			ExampleAuth.setValue(xmplRequest, for: "Request", attribute: CEFV8PropertyAttribute.none)
			ExampleAuth.setValue(xmplResponse, for: "Response", attribute: CEFV8PropertyAttribute.none)

			if let userName = CEFV8Value.createString(auth.Request.UserName),
			   let password = CEFV8Value.createString(auth.Request.Password),
			   let siteName = CEFV8Value.createString(auth.Request.SiteName) {

				xmplRequest.setValue(userName, for: "UserName", attribute: CEFV8PropertyAttribute.none)
				xmplRequest.setValue(password, for: "Password", attribute: CEFV8PropertyAttribute.none)
				xmplRequest.setValue(siteName, for: "SiteName", attribute: CEFV8PropertyAttribute.none)
			}

			if let isAuthed = CEFV8Value.createBool(auth.Response.IsAuthenticated ?? false),
			   let token = CEFV8Value.createString(auth.Response.Token),
			   let roles = auth.Response.UserRoles {

				if let userRoleArray = CEFV8Value.createArray(length: roles.count) {
					for (index, role) in roles.enumerated() {
						if let userRole = CEFV8Value.createString(role) {

							userRoleArray.setValue(userRole, at: index)
						}
					}
					xmplResponse.setValue(userRoleArray, for: "UserRoles", attribute: CEFV8PropertyAttribute.none)
				}
				xmplResponse.setValue(isAuthed, for: "IsAuthenticated", attribute: CEFV8PropertyAttribute.none)
				xmplResponse.setValue(token, for: "Token", attribute: CEFV8PropertyAttribute.none)
			}
			return ExampleAuth
		}
		return nil
	}
}

// A ONE-OFF STRUCTURE:  (similar to the app-specific one-off above)
//TODO: PRELIMINARY: we will programmatically create the following object by reflection
//				  (and it should match the one just manually created)

struct ExampleAuth {
	var Request:  ExampleRequest
	var Response: ExampleResponse
}
struct ExampleRequest {
	var UserName: String
	var Password: String
	var SiteName: String
}
struct ExampleResponse {
	var IsAuthenticated: Bool
	var Token:		String
	var UserRoles: [String]
}

// (generally deprecated)
public func CreateExampleCEFV8Object(from: Any) -> CEFV8Value? {

	let auth = Authenterface.instance
	let xmplAuth = ExampleAuth(Request: ExampleRequest(
											UserName: auth.Request.UserName ?? "",		// Actually this stuct is redundant
											Password: auth.Request.Password ?? "",		//	with our existing object,
											SiteName: auth.Request.SiteName ?? ""),		//	can we eliminate it?
										Response: ExampleResponse(
											IsAuthenticated: auth.Response.IsAuthenticated ?? false,
											Token: auth.Response.Token ?? "",
											UserRoles: auth.Response.UserRoles ?? [])
										)
	return CreateCEFV8Object(from: xmplAuth, name: "ExampleAuth")
}
