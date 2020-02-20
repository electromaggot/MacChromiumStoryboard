//
// ChromiumHandlers.swift
//	ChromiumTester demo app + Chromium BrowseProcess
//
// Handle lots o' events, including Client, LifeSpan, I/O ops (mostly to ignore them)
//	and especially, DemoApp operations coordinated with RenderProcess.
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2015.07.18
//

import Cocoa
import CEFswift


class ChromiumHandler: CEFClient, CEFLifeSpanHandler {

	static var instance = ChromiumHandler()

	public let AppUtil = NativeAppUtility()

	private var _browserList = [CEFBrowser]()
	private var _isClosing: Bool = false
	var isClosing: Bool { get { return _isClosing } }

	private let blockingSemaphore = ipcBlockingSemaphore(.CREATE)

	// from CEFClient - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	var lifeSpanHandler: CEFLifeSpanHandler? {
		print("BrowseProcess:  ChromiumHandler.LifeSpanHandler GETTER")
		return self
	}

	// from CEFLifeSpanHandler - - - - - - - - - - - - - - - - - - - - - - - -
	var OnBrowserCreatedCallback: ((CEFBrowser) -> Void)? = nil
	var IsStartPageToLoadBlank = false

	func onAfterCreated(browser: CEFBrowser) {		print("BrowseProcess:  ChromiumHandler.onAfterCreated()")
		_browserList.append(browser)

//TODO: See if this is really needed?  (Does resizing give page the "kick" it needs to start rendering, which it was having trouble with until mouse-movement?)
/*TJ - I guess not?
		if let webViewController = ChromiumViewController.instance {

			webViewController.ResizeViewToParent()
		}
TJ*/

		if let callbackFunction = OnBrowserCreatedCallback {
			// Expect callback, now having browser reference, to load its own page!

			callbackFunction(browser)
			OnBrowserCreatedCallback = nil
		}
		else if IsStartPageToLoadBlank,
		   let startingURL = URL(string: "about:blank") {
			browser.mainFrame?.loadURL(startingURL)
		}
		else {
			browser.mainFrame?.loadString(LoadingPage.HTML_WITH_INLINE_SPINNER, withURL: Bundle.main.bundleURL)
		}
	}

	func onDoClose(browser: CEFBrowser) -> CEFOnDoCloseAction {
		if _browserList.count == 1 {
			_isClosing = true
		}
		return .allow
	}

	func onBeforeClose(browser: CEFBrowser) {
		for (index, value) in _browserList.enumerated() {
			if value.isSame(as: browser) {
				value.host?.closeBrowser(force: true)
				_browserList.remove(at: index)
				break
			}
		}
	}

	// new methods
	func closeAllBrowsers(force: Bool = false) {
		_browserList.forEach { browser in
			browser.host?.closeBrowser(force: force)
		}
	}

	// CEFClient

	public var contextMenuHandler: CEFContextMenuHandler? {

		print("IGNORE RIGHT CLICK")
		return IgnoreRightClick()
	}

	public var dragHandler: CEFDragHandler? {

		print("IGNORE DRAG")
		return IgnoreDrag()
	}


	// Handle messages from RenderProcess; especially, sharing of Authentication data.
	//
	func onProcessMessageReceived(browser: CEFBrowser, processID: CEFProcessID,
								  message: CEFProcessMessage) -> CEFOnProcessMessageReceivedAction {

		print("---> BROWSER: MESSAGE RECEIVED: \(message.name)")

		if message.name.starts(with: "get") {

			switch message.name {
			case "getAuth":

				sendBackAuthenticationData(browser: browser)

			case "getDemoAppMode":

				replyDemoAppMode(browser: browser)

			default: break
			}
		} else if message.name == "LogOut" {

			if let chromiumViewController = ChromiumViewController.instance {

				chromiumViewController.LogOut()
			}

		} else {	// DemoApp-specific messages

			if message.argumentList?.size == 0 {
				print("ARGUMENT LIST EMPTY")
			}

			if let args = message.argumentList,
			   let json = args.string(at: 0),
			   let demoApp = demoAppObjectFrom(JSON: json) {

				// Store received demoAppObject for potential "all-purpose" future use:
				ChromiumViewController.instance?.fileHandler.DemoAppData = demoApp

				switch message.name {
				case "Save":

					AppUtil.PopUpOpenPanel(nil, demoApp.Request.FileType, allowMultipleFiles: true)

				case "Open":

					if let fileName = demoApp.Request.FileName,
					   let exampleId = demoApp.Request.ExampleId,
					   let fileType = demoApp.Request.FileType {

						switch fileType {
						case .REGULAR:
							blog("        (Open: \(fileName) \(fileType) \(exampleId))")
							/*let exampleId = demoApp.Request.ExampleId ?? -1
							if var fileData = AuthService.sharedInstance.GetFileData(forFileId: fileId, siteId: siteId),
							   let fileName = fileData.fileName {

								fileData.exampleId = exampleId

								let fullPath = DemoAppUtil.FileHandler.DownloadBeginning_establishFileDestination(useFileData: fileData)

								DemoAppUtil.FileHandler.DownloadFile(name: fileName, type: fileType, id: fileId, parentId: exampleId)

								if let filePath = fullPath {
									blog("Open File for EDIT: \(filePath)")

									DemoAppUtil.FileHandler.OpenFileForEdit(filePath)
								}
								blog("        (Open: \(fileName) \(siteId) \(fileId) \(fileType))")
							}*/
						case .SPECIAL:
							blog("        (Open: \(fileName) \(fileType) \(exampleId) \(demoApp.Request.IsSpecial ?? false))")
							/*let exampleId = demoApp.Request.ExampleId ?? -1
							if let fileData = AuthService.sharedInstance.GetFileData(forFileId: fileId),
							   let fileName = fileData.fileName {

								let fullPath = DemoAppUtil.FileHandler.DownloadBeginning_establishFileDestination(specialFileData: fileData)

								DemoAppUtil.FileHandler.DownloadFile(name: fileName, type: .SPECIAL, id: fileId, parentId: exampleId, sizeExpected: fileData.fileSize)

								if let filePath = fullPath {
									blog("Open File for EDIT: \(filePath)")

									DemoAppUtil.FileHandler.OpenFileForEdit(filePath)
								}
								blog("        (Open: \(fileName) \(siteId) \(fileId) \(fileType))")
							}*/
						default: break
						}
					}

				case "NavigateForward":

					AppUtil.NavigateToNextPage(fromViewController: ChromiumViewController.instance)

				default: break
				}
			}
		}
		return CEFOnProcessMessageReceivedAction.consume
	}

	private func demoAppObjectFrom(JSON: String) -> CommandProtocol? {

		let jsonDecoder = JSONDecoder()
		do {
			if let jsonData = JSON.data(using: .utf8) {

				return try jsonDecoder.decode(CommandProtocol.self, from: jsonData)
			}
		}
		catch (let error) {
			blog (.ERR, "Cannot JSON-decode: \(error)")
		}
		return nil
	}

	public func UnblockRenderProcess() {

		blockingSemaphore.Post()

		//for browser in _browserList {
		//	browser.reload(ignoringCache: false)
		//}
		//TODO: The above causes a full-redraw of the entire screen, including the left pane, which looks totally ugly.
		//	Actually, it resulted in a bug too, because apparently it may redirect the page inappropriately.
		//	I got the system semphore working, but only if I disabled sandboxing of the Render Process.
		//	If that ends up being an acceptable "final solution" this entire comment block can eventually be deleted.
	}

	// In these methods, we "think" we should only have one browser in _browserList.  However if there is more than one,
	//	it may be complicated to tell which is the one we really want.  Therefore, these operations will affect them all.
	//	So be wary if you have any kind of subbrowser/subwindow/non-trivial setup.

	public func Load(url: URL, browser: CEFBrowser) {
		browser.mainFrame?.loadURL(url)
	}
	public func Load(url: URL) {
		for browser in _browserList {
			Load(url: url, browser: browser)
		}
	}

	public func LoadLoadingSpinnerPage(browser: CEFBrowser) {
		browser.mainFrame?.loadString(LoadingPage.HTML_WITH_INLINE_SPINNER, withURL: Bundle.main.bundleURL)
	}
	public func LoadLoadingSpinnerPage() {
		for browser in _browserList {
			LoadLoadingSpinnerPage(browser: browser)
		}
	}

	public func NavigateBack(browser: CEFBrowser) {		//TODO: investigate canGoBack returning true on first page loaded
		if browser.mainFrame?.browser.canGoBack ?? false {
			browser.mainFrame?.browser.goBack()
		}
	}
	public func NavigateBack() {
		for browser in _browserList {
			NavigateBack(browser: browser)
		}
	}													//TODO: after a page load, dim appropriate button if !canGo...
	public func NavigateForward(browser: CEFBrowser) {
		if browser.mainFrame?.browser.canGoForward ?? false {
			browser.mainFrame?.browser.goForward()
		}
	}
	public func NavigateForward() {
		for browser in _browserList {
			NavigateForward(browser: browser)
		}
	}
	public func ReloadPage(browser: CEFBrowser) {
		browser.reload()
	}
	public func ReloadPage() {
		for browser in _browserList {
			ReloadPage(browser: browser)
		}
	}
	public func StopLoading(browser: CEFBrowser) {
		browser.stopLoad()
	}
	public func StopLoading() {
		for browser in _browserList {
			StopLoading(browser: browser)
		}
	}


	func sendBackAuthenticationData(browser: CEFBrowser) {

		if let message = CEFProcessMessage(name: "authData"),
		   let dictionary = CEFDictionaryValue() {

			let auth = Authenterface.instance

			if let userName = auth.Request.UserName {
				dictionary.set(userName, for: "Request.UserName")
			}
			if let password = auth.Request.Password {
				dictionary.set(password, for: "Request.Password")
			}
			if let siteName = auth.Request.SiteName {
				dictionary.set(siteName, for: "Request.SiteName")
			}

			if let isAuthenticated = auth.Response.IsAuthenticated {
				dictionary.set(isAuthenticated, for: "Response.IsAuthenticated")
			}
			if let token = auth.Response.Token {
				dictionary.set(token, for: "Response.Token")
			}
			if let roles = auth.Response.UserRoles {
				dictionary.set("\(roles)", for: "Response.UserRoles")	// array of roles as one string
			}

			if message.argumentList != nil {

				message.argumentList!.set(dictionary, at: 0)
				browser.sendProcessMessage(targetProcessID: CEFProcessID.renderer, message: message)
				return
			}
			print("ERROR! Unable to send authData message to Renderer")
		}
	}

	func replyDemoAppMode(browser: CEFBrowser) {

		if let message = CEFProcessMessage(name: "demoAppMode"),
		   let dictionary = CEFDictionaryValue() {

			let isAppRequiringAuthentication = ConfigManager.sharedInstance.IsAuthenticationBasedApp

			dictionary.set(isAppRequiringAuthentication, for: "isAuthenticationBasedApp")

			if message.argumentList != nil {

				message.argumentList!.set(dictionary, at: 0)
				browser.sendProcessMessage(targetProcessID: CEFProcessID.renderer, message: message)
				return
			}
			print("ERROR! Unable to send demoAppMode message to Renderer")
		}
	}
}


class IgnoreRightClick : CEFContextMenuHandler {

	public func onBeforeContextMenu(browser: CEFswift.CEFBrowser, frame: CEFswift.CEFFrame, params: CEFswift.CEFContextMenuParams, model: CEFswift.CEFMenuModel) {
	}
	public func onRunContextMenu(browser: CEFswift.CEFBrowser, frame: CEFswift.CEFFrame, params: CEFswift.CEFContextMenuParams, model: CEFswift.CEFMenuModel, callback: CEFswift.CEFRunContextMenuCallback) -> CEFswift.CEFOnRunContextMenuAction {
		return CEFswift.CEFOnRunContextMenuAction.showCustom
	}
	public func onContextMenuCommand(browser: CEFswift.CEFBrowser, frame: CEFswift.CEFFrame, params: CEFswift.CEFContextMenuParams, commandID: CEFswift.CEFMenuID, eventFlags: CEFswift.CEFEventFlags) -> CEFswift.CEFOnContextMenuCommandAction {
		return CEFswift.CEFOnContextMenuCommandAction.consume
	}
	public func onContextMenuDismissed(browser: CEFswift.CEFBrowser, frame: CEFswift.CEFFrame) {
	}
}

class IgnoreDrag : CEFDragHandler {

	public func onDragEnter(browser: CEFswift.CEFBrowser, dragData: CEFswift.CEFDragData, operationMask: CEFswift.CEFDragOperationsMask) -> CEFswift.CEFOnDragEnterAction {
		return CEFswift.CEFOnDragEnterAction.accept
	}

	public func onDraggableRegionsChanged(browser: CEFswift.CEFBrowser, regions: [CEFswift.CEFDraggableRegion]) {
	}
}
