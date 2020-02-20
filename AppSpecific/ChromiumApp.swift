//
// ChromiumApp.swift
//	ChromiumTester demo app + Chromium BrowseProcess
//
// Initialize Chromium overall (should be called first-thing).
// Subclass CEFApplication and CEFApp (while handling BrowseProcess events).
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2015.07.18
//

import Cocoa
import CEFswift


class ChromiumModule {

	static var cefApp: ChromiumApp? = nil
	
	// Parallel and carefully follow exact call sequence as... e.g. (CEFDemo/main.swift).
	// This mostly sets up all of Chromium (with the exception of actually creating the Browser process) all of
	//	which, through use, proved necessary BEFORE any AppDelegate or @NSApplicationMain operations are done.
	//	Otherwise while Chromium may run, may also crash due to its CrAppProtocols not conformed to in NSApp.
	//
	static func Initialize() {

		let args = CEFMainArgs(arguments: CommandLine.arguments)
		let cefApp = ChromiumApp()
		ChromiumModule.cefApp = cefApp

		_ = ChromiumApplication.shared	// force instantiation

		var settings = CEFSettings()
		settings.ignoreCertificateErrors = true

		blog("args \(args) settings \(settings) app \(String(describing: cefApp))", .DEBUG)

		_ = CEFProcessUtils.initializeMain(with: args, settings: settings, app: cefApp)
	}

	static var IsBrowserCreated: Bool {
		return cefApp?.isBrowserCreated ?? false
	}
}


class ChromiumApp: CEFApp, CEFBrowserProcessHandler {

	// NOTE that API/Web URIs are in:  DataService  (and abbrevServices.swift for ChromiumTester)

	static var IsAuthenticationInterfaceSetup = false
	
	let client: ChromiumHandler

	init() {		print("BrowseProcess:  ChromiumApp.init()")
		client = ChromiumHandler.instance
	}


	var overridableURL: URL? = nil

	var wantLoad1stPageImmediately: Bool = false

	var isBrowserCreated: Bool = false


	// cefapp
	var browserProcessHandler: CEFBrowserProcessHandler? {
		//print("BrowseProcessHandler GETTER")
		return self
	}

	// cefbrowserprocesshandler
	func onContextInitialized() {		print("BrowseProcess:  ChromiumApp.onContextInitialized()")

		var url = URL(string: ServiceAddresses.WebURLBasePage1)

		if let cmdLine = CEFCommandLine.global {	// perhaps override from command line (throwback to original CEF.swift code!)
			if let urlSwitch = cmdLine.switchValue(for: "url"), !urlSwitch.isEmpty {
				url = URL(string: urlSwitch)
			}
		}
		overridableURL = url
	}

	static func SetUpAuthenticationInterface() {
		blog("BrowseProcess calling Authenticator.setAuthentication() from ChromiumApp.onContextInitialized...", .DEFAULT)

		let authService = AuthService.sharedInstance

		let madeRequest = Authenterface.RequestData(UserName: authService.loginName,
													Password: "",	// purposely not stored
													SiteName: "main")
		
		Authenterface.instance.initialize(request: madeRequest)

		Authenterface.instance.setAuthentication(didSucceed: ChromiumViewController.IsAuthenticated,
												 httpAuthToken: authService.HttpAuthToken,
												 userRoles: authService.UserRoles ?? [])
	}

	private func createBrowser(_ winInfo: CEFWindowInfo) {

		let settings = CEFBrowserSettings()

		if wantLoad1stPageImmediately {

			isBrowserCreated = CEFBrowserHost.createBrowser(windowInfo: winInfo, client: client, url: overridableURL, settings: settings, requestContext: nil)
		}
		else {	// Don't want the page to load just yet, so instead:

			isBrowserCreated = CEFBrowserHost.createBrowser(windowInfo: winInfo, client: client, settings: settings)
		}
		print("CEFBrowserHost.createBrowser \(isBrowserCreated ? "SUCCEEDED" : "FAILED")" + (wantLoad1stPageImmediately ? " : \(overridableURL?.absoluteString ?? "<empty URL?>")" : ""))
	}

	//	IMPORTANT NOTE: On entry, fully assumes and depends upon user having already been Authenticate()d!
	//
	public func Create1stBrowserWith(chromiumView: NSView) {

		ChromiumApp.SetUpAuthenticationInterface()

		ChromiumApp.IsAuthenticationInterfaceSetup = true
		
		var winInfo = CEFWindowInfo()

		print("BrowseProcess:  setting CEFWindow as child of ChromiumViewController")
		print("                frame: \(chromiumView.frame) ...  CEFWindowInfo.rect \(winInfo.rect)")

		winInfo.setAsChild(of: chromiumView, withRect: chromiumView.frame)

		if !wantLoad1stPageImmediately {
			ChromiumHandler.instance.OnBrowserCreatedCallback = on1stBrowserCreated
		}

		createBrowser(winInfo)
	}

	private func on1stBrowserCreated(browser: CEFBrowser) {

		if let url = overridableURL {
			browser.mainFrame?.loadURL(url)
		} else {
			let errorHTML = "<html><body><h2>ERROR! Page not found: \(overridableURL?.absoluteString ?? "<URL Empty>")</h2></body></html>"
			browser.mainFrame?.loadString(errorHTML, withURL: Bundle.main.bundleURL)
		}
	}

	public func CreateAdditionalBrowserWith(newChromiumView: NSView) {

		var winInfo = CEFWindowInfo()

		winInfo.setAsChild(of: newChromiumView, withRect: newChromiumView.frame)

		createBrowser(winInfo)
	}

	public func ReloadPage() {

		if let url = overridableURL {

			client.LoadLoadingSpinnerPage()

			client.Load(url: url)
		}

		// Not doing this, because it's not fluid and doesn't seem to work on 3rd try...
		//client.RefreshReloadPageContent()
	}


	public func PumpAllMessages() {		// Won't return until shutdown!

		print(">>>>>>>> BROWSE PROCESS: ENTER MESSAGE PUMP <<<<<<<<")

		ChromiumApplication.IsPumpingMessages = true

		CEFProcessUtils.runMessageLoop()
	}
}


class ChromiumApplication : CEFApplication {	// derived in turn from NSApplication

	static var IsPumpingMessages: Bool = false


	override func terminate(_ sender: Any?) {

		if ChromiumApplication.IsPumpingMessages {

			CEFProcessUtils.quitMessageLoop()
		}
		else {		// (pre-chromium)

			CEFProcessUtils.shutDown()

			super.terminate(sender)
		}
	}
}
