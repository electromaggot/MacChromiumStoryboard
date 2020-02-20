//
// Render App & Handler.swift
//	RenderProcess, ChromiumHelper
//
// Beware! Breakpoints set here won't typically be hit, since it's non-main thread.
// To do so, you'll have to:  Debug -> Attach to Process -> ChromiumTester Helper
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2017.11.08
//

import Darwin
import CEFswift


class App: CEFApp, CEFRenderProcessHandler {

	var doesAppRequireAuthentication = false

	var jsHandler: JSHandler {			//TODO: Contain this as JSHandler singleton?
		if jsHandlerInstance == nil {
			jsHandlerInstance = JSHandler()
		}
		return jsHandlerInstance!
	}
	private var jsHandlerInstance: JSHandler? = nil

	var renderProcessHandler: CEFRenderProcessHandler? {
		//print("RenderProcessHandler GETTER")
		return self
	}

	func onWebKitInitialized() {
		print("RenderProcess:  onWebKitInitialized")	// academic

		// Uncomment this to give you time to: Debug > Attach to Process > ChromiumTester Helper (the 2nd higher-PID one)
		//	if you want your breakpoints in this *separate process* to ever be hit!
		/*var seconds = 30
		while seconds > 0 {
			sleep(1)
			print("RENDERER WAITING \(seconds)...")
			secs -= 1
		}*/
	}
	func onBrowserCreated(browser: CEFBrowser) {
		print("RenderProcess:  onBrowserCreated")		// academic

		sendRequestDemoAppMode(toBrowser: browser)
	}

	func onContextCreated(browser: CEFBrowser, frame: CEFFrame, context: CEFV8Context) {
		print("RenderProcess:  onContextCreated  (doesAppRequireAuthentication \(doesAppRequireAuthentication ? "TRUE" : "FALSE"))")
		context.enter()

		if doesAppRequireAuthentication {
			createDemoAppObject(inContext: context, forBrowser: browser)
		}

		context.exit()
	}

	private func createDemoAppObject(inContext context: CEFV8Context, forBrowser browser: CEFBrowser) {

		sendRequestAuthenticationData(toBrowser: browser)

		if let globj = context.globalObject,
		   let demoAppObj = CEFV8Value.createObject() {

			var nSubscriptions = 0

			for method in JSHandler.Method.allCases {	// "subscribe" to all the Methods we support

				defineLocal(method: method, inObject: demoAppObj)

				nSubscriptions += 1
			}
			globj.setValue(demoAppObj, for: JSHandler.NAME, attribute: CEFV8PropertyAttribute.none)

			jsHandler.Browser = browser

			//blog(.STATUS, "DEMOAPPOBJECT demoAppObject CREATED, \(nSubscriptions) methods subscribed to.", .DEBUG)
			print("BLOG .STATUS .DEBUG: DEMOAPPOBJECT demoAppObject CREATED, \(nSubscriptions) methods available.")
			print("     (awaiting initial call to: \(JSHandler.Method.GetAuthenticationData.rawValue))")
		}
	}

	private func defineLocal(method: JSHandler.Method, inObject: CEFV8Value) {

		let methodName = method.rawValue

		if let function = CEFV8Value.createFunction(name: JSHandler.PREFIX + methodName, handler: jsHandler) {
			inObject.setValue(function, for: methodName, attribute: CEFV8PropertyAttribute.none)
		}
	}

	private func sendRequestAuthenticationData(toBrowser: CEFBrowser) {

		if let message = CEFProcessMessage(name: "getAuth") {
			// no parameters!
			toBrowser.sendProcessMessage(targetProcessID: CEFProcessID.browser, message: message)
		}
	}

	private func sendRequestDemoAppMode(toBrowser: CEFBrowser) {

		if let message = CEFProcessMessage(name: "getDemoAppMode") {
			toBrowser.sendProcessMessage(targetProcessID: CEFProcessID.browser, message: message)
		}
	}


	// Handle messages from BrowserProcess; especially sharing of Authentication data.
	//
	func onProcessMessageReceived(browser: CEFBrowser, processID: CEFProcessID,
								  message: CEFProcessMessage) -> CEFOnProcessMessageReceivedAction {

		print("---> RENDERER: MESSAGE RECEIVED: \(message.name)")

		switch message.name {

		case "authData":

			if let args = message.argumentList,
			   let dict = args.dictionary(at: 0) {

				let auth = Authenterface.instance

				auth.Request.UserName = dict.string(for: "Request.UserName")
				auth.Request.Password = dict.string(for: "Request.Password")
				auth.Request.SiteName = dict.string(for: "Request.SiteName")

				auth.Response.IsAuthenticated = dict.bool(for: "Response.IsAuthenticated")
				auth.Response.Token = dict.string(for: "Response.Token")

				var arrayOfRoleStrings: [String]? = nil
				if let stringOfRoles = dict.string(for: "Response.UserRoles") {
					// this is a single-string JSON representation of an array of strings, so convert it
					let dataRoles = Data(stringOfRoles.utf8)
					do {
						arrayOfRoleStrings = try JSONSerialization.jsonObject(with: dataRoles) as? [String]
					} catch {
						print(error)
					}
				}
				auth.Response.UserRoles = arrayOfRoleStrings
			}

		case "demoAppMode":

			if let args = message.argumentList,
			   let dict = args.dictionary(at: 0) {

				doesAppRequireAuthentication = dict.bool(for: "isAuthenticationBasedApp")
			}

		default: break
		}
		return CEFOnProcessMessageReceivedAction.consume
	}
}
