//
// AppDelegate.swift
//	BrowseProcess, ChromiumTester
//
// Note that whereas the usual Xcode application would include @NSApplicationMain
//	which abstracts away a lot of underlying plumbing (like message pump or final
//	(unreturning) call to _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv))
//	for CEF we need to set all that up ourselves, so it's excluded here.
//
// Created by Tadd Jensen on 5/3/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2015.07.18
//

import Cocoa

//@NSApplicationMain			// (see comment above)
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		blog("BrowseProcess:  APPLICATION DID FINISH LAUNCHING")

		//TODO: FIGURE_OUT: Does this method even get called?
	}

	let semaphore = ipcBlockingSemaphore(.CREATE)

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
		blog("BrowseProcess:  APPLICATION WILL TERMINATE")
	}

	func createApplication() {		blog("BrowseProcess:  createApplication()")
		_ = NSApplication.shared
		// The following is left for "academic" purposes, as the storyboard's menu doesn't
		//	seem to be loading, so perhaps this NIB approach does.
		//		Bundle.main.loadNibNamed(NSNib.Name("MainMenu"), owner: NSApp, topLevelObjects: nil)
		NSApp.delegate = self
	}

	func terminateApplication() {	blog("BrowseProcess:  terminateApplication()")
		terminateChromiumBrowsers()
	}

	func tryToTerminateApplication(app: NSApplication) {
		terminateChromiumBrowsers()
	}

	func terminateChromiumBrowsers() {
		let handler = ChromiumHandler.instance
		if !handler.isClosing {
			handler.closeAllBrowsers(force: false)
		}
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		return .terminateNow
	}
}
