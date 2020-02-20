//
// JSHandler.swift
//	RenderProcess, ChromiumHelper
//
// Churn through commands particularly via Javascript from the web content.
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation
import CEFswift


public class JSHandler : CEFV8Handler {

	public static let NAME = "jsHandler"

	public static var PREFIX: String { return NAME + "." }

	public enum Method: String, CaseIterable {

		case GetAuthenticationData	= "getAuthenticationData"
		case NavigateAppForward		= "navigateAppForward"
		case LogOut					= "logout"
		case OpenFile				= "openFile"
		case SaveFile				= "saveFile"
		case SaveSpecialFile		= "saveSpecialFile"
		case AddActionHere			= "someNewAction"
	}

	public var Browser: CEFBrowser? = nil	//TODO: Clean up handling of this!


	func initialize() {

		print("Initializing CEFV8Handler")		// academic
	}

	//public func execute(name: String, object: CEFV8Value, arguments: [CEFV8Value], retval: inout CEFV8Value) -> CEFV8Result? {
	public func execute(name: String, object: CEFV8Value, arguments: [CEFV8Value]) -> CEFV8Result? {

		print("execute()ing: \(name)(\(arguments)")
		//DumpCEFV8(object: object, name: "object")
		for (index, argument) in arguments.enumerated() {
			DumpCEFV8(object: argument, name: "argument[\(index)]")
		}

		var result: CEFV8Value? = nil

		if let method = Method(rawValue: name.replacingOccurrences(of: JSHandler.PREFIX, with: "")) {

			switch method {
			case Method.GetAuthenticationData:
				if let loginAuth = newAuthenticationData() {
					print("RETURNING:")
					DumpCEFV8(object: loginAuth, name: "loginAuth")
					//retval = loginAuth		// not this way!
					//return CEFV8Result.success(CEFV8Value.createBool(true)!)
					return CEFV8Result.success(loginAuth)
				}
			case Method.NavigateAppForward:
				forceAppToNextScreen(someActionId: arguments[0].intValue)

			case Method.OpenFile:
				result = requestOpenFile(.REGULAR, fileName: arguments[0].stringValue,
										 exampleId: arguments[1].intValue, isSpecial: arguments[2].boolValue)

			case Method.SaveFile:
				result = requestSaveFile(.REGULAR, fileName: "?", exampleId: arguments[0].intValue)

				if let request = result {
					DumpCEFV8(object: request, name: "SAVE FILE REQUEST MESSAGE:")
				}

				/*TODO:
					We want to block here.
					For instance, to sleeped-busy-wait on a system semaphore.
					Something like this:

				var secondsToRetry = 30
				while !semaphoreSet && secondsToRetry > 0 {
					sleep(1)
					secondsToRetry -= 1
				}*/

				blockingSemaphore.Wait()

			case Method.SaveSpecialFile:
				let special =  arguments.count > 1 && arguments[1].isBool ? arguments[1].boolValue : nil

				result = requestSaveSpecialFile(.SPECIAL, fileName: "?", exampleId: arguments[0].intValue, isSpecial: special)
				blockingSemaphore.Wait()

			case Method.LogOut:
				sendBrowser(messageName: CommandProtocol.Operation.LOG_OUT.rawValue)

			default: break
			}

			if let validResult = result {
				return CEFV8Result.success(validResult)
			}
			return CEFV8Result.success(object)
		}
		return CEFV8Result.failure("\(JSHandler.NAME) can't handle: \(name)(\(arguments))")
	}


	// newAuthenticationData depends on Authenticator already having been populated on the Browser
	//	side via an API call: HTTP POST account/authenticate, which returned a token.
	//TODO: If the token expired, we could re-query via sendRequestAuthenticationData() but
	//	pass a flag dictating that the API be hit again to re-authenticate.
	//
	private func newAuthenticationData() -> CEFV8Value? {

		print("newAuthenticationData... \(Authenterface.instance.Request.UserName ?? "<userName nil>")")
		print("                         \((Authenterface.instance.Response.IsAuthenticated ?? false) ? "AUTHENTICATED" : "NOT authenticated")")
		print("                         \(Authenterface.instance.Response.Token ?? "<token nil>")")

		// workInProgressTest()
		// return authenticationDataAsCEFV8Object()		// onceuponatime we were actually constructing this object

		return cefV8ValueFrom(JSON: encodableObjectAsJSON(Authenterface.instance))
	}

	private func cefV8ValueFrom(JSON: String?) -> CEFV8Value? {

		guard let json = JSON else { return nil }

		return CEFV8Value.createString(json)
	}
	private func cefValueFrom(JSON: String?) -> CEFValue? {

		if let json = JSON,
		   let returnValue = CEFValue(),
		   returnValue.setString(json) {

			return returnValue
		}
		return nil
	}

	private func encodableObjectAsJSON<T : Encodable>(_ object: T) -> String? {

		let jsonEncoder = JSONEncoder()
		do {
			let jsonData = try jsonEncoder.encode(object)
			return String(data: jsonData, encoding: String.Encoding.utf8)
		}
		catch (let error) {
			//blog (.ERR, "Cannot JSON-encode: \(error)")
			print("BLOG .ERR:  Cannot JSON-encode: \(error)")
		}
		return nil
	}


	private func forceAppToNextScreen(someActionId: Int) {

		if someActionId > 0 {	// simplistic validation

			_ = sendBrowser(request: CommandProtocol(operation: .NAV_NEXT,
												 destinationId: someActionId))
			print("NavigateAppForward - destinationId \(someActionId)")
		}
		else {
			print("ERROR: NavigateAppForward INVALID destinationId \"\(someActionId)\"")
		}
	}


	private func requestOpenFile(_ type: CommandProtocol.FileType, fileName: String, exampleId: Int, isSpecial: Bool? = nil) -> CEFV8Value? {

		return sendBrowser(request: CommandProtocol(operation: .OPEN,
													 fileType: type,
													 fileName: fileName,
														anyId: exampleId,
													isSpecial: isSpecial))
	}

	private func requestSaveFile(_ type: CommandProtocol.FileType, fileName: String, exampleId: Int) -> CEFV8Value? {

		return sendBrowser(request: CommandProtocol(operation: .SAVE,			// Regular File
													 fileType: type,
													 fileName: fileName,
														anyId: exampleId))
	}
	private func requestSaveSpecialFile(_ type: CommandProtocol.FileType, fileName: String, exampleId: Int, isSpecial: Bool?) -> CEFV8Value? {

		return sendBrowser(request: CommandProtocol(operation: .SAVE,			// Conditional File
													 fileType: type,
													 fileName: fileName,
														anyId: exampleId,
													isSpecial: isSpecial))
	}


	private func sendBrowser(request: CommandProtocol) -> CEFV8Value? {

		let json = encodableObjectAsJSON(request)

		if let args = cefValueFrom(JSON: json),
		   let operation = request.Request.Operation {

			sendBrowser(messageName: operation.rawValue, jsonArgs: args)
		}
		return cefV8ValueFrom(JSON: json)
	}

	private func sendBrowser(messageName: String, jsonArgs: CEFValue? = nil) {

		if let browser = Browser,
		   let cefMessage = CEFProcessMessage(name: messageName) {

			if let args = jsonArgs,
			   cefMessage.argumentList != nil {

				cefMessage.argumentList!.set(args, at: 0)
			}

			browser.sendProcessMessage(targetProcessID: CEFProcessID.browser, message: cefMessage)
		}
	}
}
