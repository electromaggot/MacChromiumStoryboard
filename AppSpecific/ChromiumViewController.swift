//
// ChromiumViewController.swift
//	ChromiumTester demo app + Chromium BrowseProcess
//
// Created by Tadd Jensen on 6/5/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Cocoa
import CEFswift


class ChromiumViewController: NSViewController {

	@IBOutlet var ChromiumWebView: NSView!
	@IBOutlet weak var buttonMore: NSButton!
	@IBOutlet weak var labelStatus: NSTextField!

	static var instance: ChromiumViewController? = nil

	static var IsUserLoggedIn = false
	static var IsLoginInProcess = false

	static var IsAuthenticated: Bool { return IsUserLoggedIn || IsLoginInProcess }


	let appUtil = ChromiumHandler.instance.AppUtil

	let fileHandler = ChromiumHandler.instance.AppUtil.FileHandler

	// VIEW LIFECYCLE

	override func viewDidLoad() {
		super.viewDidLoad()

		ChromiumViewController.instance = self

		print("=======ChromiumViewController viewDidLoad========")

		view.wantsLayer = true
		if let layer = view.layer {
			layer.backgroundColor = CGColor.init(gray: 0.5, alpha: 1.0)
		}

		labelStatus.stringValue = "Below is the Chromium Web View, rendering web content.  This here bar is part of the storyboard.  [hide it!]"

		//TODO: add to next page:
		//"(This bar is storyboard-defined with app-implemented browser controls.)"
	}

	// Note that viewDidAppear() and even viewDidLayout() may run before the browser's contained
	//	view is created, so trying to affect it in those methods may be ineffective...

	override func viewDidAppear() {
		super.viewDidAppear()

		verifyAuthenticated()

		if !ChromiumModule.IsBrowserCreated {

			startChromium()
		}
		else if ChromiumViewController.IsLoginInProcess {

			reloadPage()
		}

		if ChromiumViewController.IsLoginInProcess {
			ChromiumViewController.IsLoginInProcess = false

			ChromiumViewController.IsUserLoggedIn = true
		}

		onStartupOptionallyDownloadUsersFiles()
	}


	public func LogOut() {

		ChromiumViewController.IsUserLoggedIn = false

		cleanUpOnLogOut()
	}


	// INITIATE/TERMINATE

	private func startChromium() {

		if let ourWebView = ChromiumWebView,
		   let cefApp = ChromiumModule.cefApp {

			cefApp.Create1stBrowserWith(chromiumView: ourWebView)
		}

		AppMain.FallOutOfPreChromiumRunLoop()
	}

	private func reloadPage() {

		if let cefApp = ChromiumModule.cefApp {

			cefApp.ReloadPage()
		}
	}

	private func cleanUpOnLogOut() {

		appUtil.CleanUpOnLogOut()
		Authenterface.instance.clearAll()
		
		dismiss(self)
	}


	// IMPLEMENT

	private func onStartupOptionallyDownloadUsersFiles() {

		let authenticator = Authenterface.instance
		if let user = authenticator.Request.UserName {	// that is IF the user logged in!
			fileHandler.DownloadAllFiles(forUserName: user)
		}
	}

	// This test is completely optional, especially if -- even upon authentication failure -- we still
	//	want to go into the Web Content, where there may be another login prompt and chance to log in.
	// Otherwise...
	// Technically we shouldn't be here if the login failed, it having already notified user via pop-up,
	//	but just in case, or somehow Angular itself fails authentication,
	//	to not irreversably segue to a blank screen...
	//
	private func verifyAuthenticated() {

		if !ChromiumViewController.IsAuthenticated && ConfigManager.sharedInstance.IsAuthenticationBasedApp {
			print("POP-UP: Failed to Authenticate, yet still entering Chromium in Authentication-Based-App.")
		}
	}
}
