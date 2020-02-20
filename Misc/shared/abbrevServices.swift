//
// abbreviated Data/Web/Auth/HTTP Services
//

import Foundation
import AppKit
import WebKit		// for WebOpenPanelResultListener


// DATA / WEB SERVICES

open class ServiceAddresses {

	static let WebServiceURLBase = "https://192.168.101.1:443/"

	static let WebURLBasePage1 = "file:///Users/Proj/Minor/MyGitHub/MacChromiumStoryboard/demoIndex.html"

	// CAN'T DO THIS!  (A relative-path URL)  So we instead...
	//static var WebURLBasePage1 = "file://../cefDemo_Index.html"
	// ...load it programmatically as an HTML string from here:
	static let WebRelativePath = "./demoIndex.html"
	// Then load that HTML content directly into the WebView.
	// You'll want to delete the above 5 lines and replace them with something like this:
//	static var WebURLBasePage1 = "https://yourCompany.com/Index.html"

	static let WebURLBasePage2 = "https://threejs.org/examples/webgl_animation_keyframes.html"
}


// AUTH SERVICE

open class AuthService {

	static let sharedInstance = AuthService()

	public enum AuthenticationResult {
		case PASS
		case FAIL
		case TIMEOUT
		case ERROR
		case OTHER
		case UNKNOWN
	}

	public var ErrorMessage: String? = nil

	let protops = ProtocolOperations()

	var authToken = ""

	public var HttpAuthToken: String { return authToken }

	var userRoles: [String]? = nil

	public var UserRoles: [String]? { return userRoles }

	var loginName: String = ""

	public var LoginName: String	{ return loginName }


	public enum WebServiceRequest: String {

		case LOGIN_AUTHENTICATE	= "accounts/%s/authenticate"
		case OTHER_SERVICE		= "example/data"
	}

	private func buildAPIQuery(uriFor: WebServiceRequest, substituting: String? = nil) -> String? {

		var strq: NSString = uriFor.rawValue as NSString
		if strq.contains("%s") {					// arbitrary insertion
			if let subst = substituting {
				strq = strq.replacingOccurrences(of: "%x", with: subst) as NSString
			}
			else {
				abortQuery(dependencyName: "arbitrary \"\(substituting ?? "")\" replacing \"%x\"", queryString: strq)
				return nil
			}
		}
		let resultStrQ = strq as String
		if !resultStrQ.isEmpty {
			return resultStrQ
		} else {
			return nil
		}
	}

	private func abortQuery(dependencyName: String, queryString: NSString) {

		blog(.INTERNAL, "ABORT query: \(queryString)", .WEBSERVICE)
		blog(.INTERNAL, "    DEPENDENCY on undefined " + dependencyName, .WEBSERVICE)
	}

	private func fullURL(_ baseURL: String) -> String {
		return ServiceAddresses.WebServiceURLBase + baseURL
	}


	public func Authenticate(login: String, password: String, site: String) -> AuthenticationResult {

		if let queryLogin = buildAPIQuery(uriFor: WebServiceRequest.LOGIN_AUTHENTICATE, substituting: site) {

			let request: [String: Any] = [			//	let request = "{\"UserName\":\"\(login)\","
				"UserName": login,					//				+  "\"Password\":\"\(password)\"}"
				"Password": password
			]
			var jsonData: NSData
			var jsonString: String = ""
			do {
				jsonData = try JSONSerialization.data(withJSONObject: request, options: JSONSerialization.WritingOptions()) as NSData
				jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
			} catch {
				blog("JSONSerialization FAIL: \(error)")
			}
			let isValidJsonObj = JSONSerialization.isValidJSONObject(request)
			blog("is valid json object: \(isValidJsonObj) ")
			blog("  Authenticating: HTTP POST \(fullURL(queryLogin))")
			blog("    Payload: \(request)")

			// blocking HTTP POST:
			if let dictReply = protops.HttpPost(toUrlString: fullURL(queryLogin),
												payload: jsonString, .WEBSERVICE) {
				if let token = dictReply["Token"],
				   let authString = token as? String/*,
				   let authData = authString.data(using: String.Encoding.utf8)*/ {

					//authToken = authData.base64EncodedString(options: [])
					authToken = authString
					blog("Token: \(authToken)")

					// save off UserRoles too						// response e.g.:
					if let roles = dictReply["UserRoles"],			//	diag: RECV  {
					   let roleStrings = roles as? [String] {		//		Token = "ILGwTMYr/9a484GbswnPAw==";
																	//		UserRoles =     (
						userRoles = roleStrings						//			AverageUser, TestingSite, AuthenticatedUser
						blog("RoleStrings: \(roleStrings)")			//		);
					}												//	}
					return .PASS
				}
			}
			if protops.Result == .FAIL_TIMEOUT {
				return .TIMEOUT
			}
		}

		blog(.ERROR, "LOGIN FAILED!  (\(login) : \(password.count)-character password)", .WEBSERVICE)
		return .FAIL
	}
}


// HTTP OPERATIONS

class ProtocolOperations {

	public enum ResultStatus {
		case NONE
		case SUCCESS
		case FAIL_TIMEOUT
		case FAIL_SYNTAX
		case FAIL_OTHER
	}
	var result: ResultStatus = .NONE
	public var Result: ResultStatus {
		get { return result }
	}

	public var HttpStatusCode: Int = 0


	let secondsToWait: Double = 3.0
	let untilReply = DispatchSemaphore(value: 0)

	var dictionaryReceived: NSDictionary? = nil

	var httpRestCallback: ((NSDictionary) -> Void)? = nil

	fileprivate var logTo: Bucket = .NONE


	
	// HTTP POST BLOCKING until response received, handling the callback herein.
	//
	public func HttpPost(toUrlString: String, payload: String,
						 authToken: String? = nil,
						 addHeader: [String : String] = [:],
						 _ logging: Bucket = .NONE) -> NSDictionary? {
		logTo = logging
		httpRestCallback = nil

		var mutableHeader = addHeader

		var logMsg = payload

		if let token = authToken {
			mutableHeader["Authorization"] = "Token \(token)"
			logMsg += " (token: \(token))"
		}

		let _/*task*/ = requestPOST(urlString: toUrlString, urlParameters: [:],
							   body: payload, completionHandler: receiveHttpRestReply,
							   additionalHeaders: mutableHeader)

		if untilReply.wait(timeout: .now() + secondsToWait) == .timedOut {

			result = .FAIL_TIMEOUT
			blog(.ERROR, "Timeout awaiting Server reply for \(secondsToWait) seconds. \(toUrlString)", logTo)
			return nil
		}
		//ProtocolOperations.CheckForNetworkError(task)

		blog(.NORM, "POST  (\(logMsg))", logTo)

		if let recvDict = dictionaryReceived {
			result = .SUCCESS
			blog(.NORM, "RECV  \(recvDict)", logTo)
			return recvDict
		} else {
			blog(.WARN, "(nothing returned)", logTo)
		}
		result = .FAIL_OTHER
		return nil
	}
	// (the above and the below HttpPost()s are either/or)

	// HTTP POST WITH callback function; we'll call it when we get the response.
	//
	public func HttpPost(toUrlString: String, payload: String,
						 callbackFunc: @escaping (NSDictionary) -> Void,
						 _ logging: Bucket = .NONE) {
		logTo = logging
		httpRestCallback = callbackFunc

		_ = requestPOST(urlString: toUrlString, urlParameters: [:],
						body: payload, completionHandler: receiveHttpRestReply)

		blog(.NORM, "POST  (\(payload)\n", logTo)
	}

	// NON-THREAD-SAFE receive/process response to immediately-prior HTTP POST
	//	(or PUT) request - unsafe because it uses a single callback reference that
	//	may be overwritten, SO HANDLE STRICTLY SYNCHRONOUSLY.
	//
	private func receiveHttpRestReply(data: Data?, response: URLResponse?, err: Error?) {

		if let receivedata = data {

			if let httpUrlResponse = response as? HTTPURLResponse {

				HttpStatusCode = httpUrlResponse.statusCode

				//if HttpStatusCode == HttpUtility.HttpStatus.OK.rawValue { // NOTE that this is
				//	NOT done! ...since errors return responses too, like { "Message" : "...error message..." }

				if let mimeType = httpUrlResponse.mimeType {
					var dictionary: NSDictionary = [:]

					if mimeType.contains("json") {
						if let dict = dictionaryFrom(jsonData: receivedata) {
							dictionary = dict
						}
					}
					else if mimeType.contains("html") {
						dictionary = ["html" : String(data: receivedata, encoding: .utf8) as Any]
					} else {
						dictionary = ["data" : receivedata]
					}
					// put into a dictionary, which is what we're returning to parent
					if let callbackFunc = httpRestCallback {
						callbackFunc(dictionary)
					} else {
						dictionaryReceived = dictionary
						untilReply.signal()
					}
				}
			}
			else if let strData = String(data: receivedata, encoding: String.Encoding.utf8) {
				//TODO: Handle error better than just logging/printing it?
				if err != nil {
					result = .FAIL_OTHER
				}
				blog(.ERROR, "GOT: \(strData)  URLResponse: \(String(describing: response))  Error: \(String(describing: err))", logTo)
			}
		}
	}


	// Use Apple's JSON parser to convert returned Data/jsonString into a dictionary.
	//
	private func dictionaryFrom(jsonData: Data) -> NSDictionary? {

		do {
			let arrOrDict = try JSONSerialization.jsonObject(with: jsonData, options: [])

			if let dictionary = arrOrDict as? NSDictionary {
				return dictionary
			}
			else if let dictArray = arrOrDict as? NSArray {
				if dictArray.count > 0 {
					if let dictionary = dictArray.firstObject as? NSDictionary {
						return dictionary
					}
				}
			}
			blog(.ERROR, "JSON received is neither dictionary nor array-of-dictionaries.", logTo)
		}
		catch {
			blog(.ERROR, "exception in parsing dictionaryFrom JSON: \(jsonData)", logTo)
		}
		result = .FAIL_SYNTAX
		return nil
	}


	func requestPOST(urlString: String, urlParameters: [String : AnyObject], body: String,
					 completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void,
					 additionalHeaders: [String : String] = [:],
					 contentType: String = "application/json; charset=utf-8",	// default request is JSON
		alternatelyLogTo: Bucket? = nil) -> URLSessionTask? {

		HttpStatusCode = 0

		let parameterString = urlParameters.stringFromHttpParameters()
		let paramPreceder = parameterString.isEmpty ? "" : "?"
		let constructedString = "\(urlString)\(paramPreceder)\(parameterString)"

		if let requestURL = URL(string: constructedString) {
			if let logIt = alternatelyLogTo {
				blog(.NORM, "POST: \(requestURL)", logIt)
			}
			var request = URLRequest(url: requestURL)
			request.httpMethod = "POST"
			request.setValue(contentType, forHTTPHeaderField: "Content-Type")
			request.httpBody = body.data(using: .utf8)

			for header in additionalHeaders {
				request.addValue(header.value, forHTTPHeaderField: header.key)
			}

			let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
			task.resume()

			return task
		}
		result = .FAIL_SYNTAX
		blog(.ERR, "POST can't form URL from: \(constructedString)", alternatelyLogTo ?? logTo)
		return nil
	}

}


// FILE SERVICE

class DemoAppFileHandling {

	public var DemoAppData: CommandProtocol? = nil

	public var ExampleFileId: Int = 0

	public func DownloadAllFiles(forUserName: String) {
		print("  fileHandler.DownloadAllFiles(forUserName: \(forUserName))")
	}

	public func DownloadFile(name: String, type: CommandProtocol.FileType, id: Int, parentId: Int, sizeExpected: Int? = nil) {
		print("  fileHandler.DownloadFile(name: \(name), type: \(type.rawValue), id: \(id), parentId: \(parentId), sizeExpected: \(sizeExpected ?? -1))")
	}

	public func OpenFileForEdit(_ fileName: String) {
		print("  fileHandler.OpenFileForEdit(\(fileName))")
	}
}

// WEB UTILITY

class NativeAppUtility {

	let FileHandler = DemoAppFileHandling()

	public func CleanUpOnLogOut() {
		print("  nativeAppUtility.CleanUpOnLogOut()")
	}

	public func NavigateToNextPage(fromViewController: ChromiumViewController?) {

		if let viewController = fromViewController,
		   let window = fromViewController?.view.window,
		   let windowContent = window.contentViewController,
		   let stobo = windowContent.storyboard {

			let idScene = SecondCEFViewController.STORYBOARD_ID
			if let nextScreen = stobo.instantiateController(withIdentifier: idScene) as? NSViewController {

					viewController.present(nextScreen as NSViewController, animator: SlideTransitionAnimator())

			}	//NOTE: windowContent.presentViewController(...) does NOT return to self properly!
		}
	}

	public func PopUpOpenPanel(_ resultListener: WebOpenPanelResultListener? = nil,
							   _ fileType: CommandProtocol.FileType? = nil,
							   allowMultipleFiles: Bool = false) {

		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.allowsMultipleSelection = allowMultipleFiles

		openPanel.begin { (result) in
			if result.rawValue == NSFileHandlingPanelOKButton {

//				self.PopUpProgressIndicator()	// temporarily show indeterminant progress (but better than nothing)

				self.backgroundHandleOpenPanelSelected(URLs: openPanel.urls, fileType: fileType, resultListener)
			}
			else {
				ChromiumHandler.instance.UnblockRenderProcess()
			}
		}
	}
	private func backgroundHandleOpenPanelSelected(URLs: [URL], fileType: CommandProtocol.FileType?, _ httpUploader: WebOpenPanelResultListener? = nil) {
		DispatchQueue.global().async {

			var filepathArray: [String] = []
			for url in URLs {
				let urlPath = url.path

				if let filename = String(describing: urlPath).removingPercentEncoding {
//					if self.warnIfUploadingPackageDirectory(named: filename) {
//						self.HideProgressIndicatorPopUp()
//						continue
//					}
					filepathArray.append(filename)
					blog(.STATUS, "UPLOAD! \(filename)", .DEBUG)
				}
				else {
					blog(.ERROR, "Upload FAIL, bad filename? \(urlPath)", .DEBUG)
				}
				// Don't need this...
				//addFileFromDemoApp(siteid, fileid, filename, status, uploaded, startupfile)
			}	//	...as the upload is either: handled automatically by the browser/js components, or via copy.

			if !filepathArray.isEmpty, let filetype = fileType {
/*				for (index, filepath) in filepathArray.enumerated() {
					let filename = (filepath as NSString).lastPathComponent

					// First, try "uploading" via copy over the network share.  This allows uploads > 2 GB.
					self.PopUpProgressIndicator()

					if self.FileHandler.ExhaustiveUploadOrCopy(pathString: filepath, fileType: filetype, id: -1) {

						self.HideProgressIndicatorPopUp()

						if let fileId = self.FileHandler.CurrentFileId {
							filepathArray.remove(at: index)

							self.ContainerRefreshAjaxReloadContent(filename: filename, fileId: fileId, parentId: -1)
						}
					}
				}
*/				if !filepathArray.isEmpty {	// If that utterly fails or files remain not uploaded, can still try the HTTP Upload way...
					if let uploader = httpUploader {
						uploader.chooseFilenames(filepathArray)
					} else {
						blog(.STATUS, "No HTTP Uploader/ResultListener available, \(filepathArray.count) files remain: \(filepathArray) \(filetype)", .DEBUG)
//						self.HideProgressIndicatorPopUp()
ChromiumHandler.instance.UnblockRenderProcess()
					}
				}
			}
			else {
				blog(.WARN, "No files selected to UPLOAD.", .DEBUG)
			}
		}
	}

}


// CONFIG MANAGER

class ConfigManager {

	static let sharedInstance = ConfigManager()

	public var IsAuthenticationBasedApp: Bool {

		return true		//TJ: return StartingViewController.IsLogin
	}
}


// QUICK CONVENIENT EXTENSIONS

extension String {
	// Percent escapes values to be added to a URL query as specified in RFC 3986.
	// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
	// http://www.ietf.org/rfc/rfc3986.txt
	// :returns: Returns percent-escaped string.

	// Note that this is more agressive, escaping more "otherwise human readable" characters,
	//	than for instance GeneralUtility.UrlPathFrom, which tries to keep URLs mostly legible.

	func addingPercentEncodingForURLQueryValue() -> String {
		let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

		return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!
	}
}

extension Dictionary {
	// Build string representation of HTTP parameter dictionary of keys and objects.
	// Also percent-escapes in compliance with RFC 3986, http://www.ietf.org/rfc/rfc3986.txt
	// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent-escaped.

	func stringFromHttpParameters() -> String {
		let parameterArray = self.map { (key, value) -> String in
			var percentEscapedKey: String = "keyNIL"
			var percentEscapedValue: String = "valueNIL"
			if let keyString = key as? String {
				percentEscapedKey = keyString.addingPercentEncodingForURLQueryValue()
			}
			if let valueString = value as? String {
				percentEscapedValue = valueString.addingPercentEncodingForURLQueryValue()
			}
			return "\(percentEscapedKey)=\(percentEscapedValue)"
		}
		return parameterArray.joined(separator: "&")
	}
}


// ETC.

public class LoadingPage {
	static let HTML_WITH_INLINE_SPINNER = """
		<!DOCTYPE html><html><head><style>
			img{display:block;margin:auto;}
			.outer{display:flex;align-items:center;justify-content:center;height:100vh;}
			.inner{display:inline-block;}</style>
		<title> Loading...
		</title></head>
		<body><div class="outer"><div class="inner">
			<img src="data:image/gif;base64,
				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
				"/><H2>Loading...</H2>
		</div></div></body></html>
	"""
}
