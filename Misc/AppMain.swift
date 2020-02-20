//
// AppMain.swift
//	ChromiumTester demo app + Chromium BrowseProcess
//
// Created by Tadd Jensen on 6/5/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Cocoa


class AppMain {

	static var Window: NSWindow? = nil

	static var applicationClass: NSApplication.Type {
		guard let principalClassName = Bundle.main.infoDictionary?["NSPrincipalClass"] as? String else {
			fatalError("Seems like `NSPrincipalClass` was missed in `Info.plist` file.")
		}
		guard let principalClass = NSClassFromString(principalClassName) as? NSApplication.Type else {
			fatalError("Unable to create `NSApplication` class for `\(principalClassName)`")
		}
		return principalClass
	}

	static var mainStoryboard: NSStoryboard {
		guard let mainStoryboardName = Bundle.main.infoDictionary?["NSMainStoryboardFile"] as? String else {
			fatalError("Looks like `NSMainStoryboardFile` was missed in `Info.plist` file.")
		}
		let storyboard = NSStoryboard(name: mainStoryboardName, bundle: Bundle.main)
		return storyboard
	}

	/* Again left in for academic purposes if menu can't be loaded from storyboard; see AppDelegate too.
	static var menu: NSNib {
		guard let nib = NSNib(nibNamed: NSNib.Name("MainMenu"), bundle: Bundle.main) else {
			fatalError("Resource `MainMenu.xib` is not found in the bundle `\(Bundle.main.bundlePath)`")
		}
		return nib
	}*/

	static var windowController: NSWindowController {
		guard let wc = mainStoryboard.instantiateInitialController() as? NSWindowController else {
			fatalError("Initial controller is not `NSWindowController` in storyboard `\(mainStoryboard)`")
		}
		Window = wc.window
		//blog("windowController.screen \(String(describing: Window?.screen))")
		return wc
	}

	// IMPLEMENTATIONS

	// Do what... NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) ...does.
	//
	static func ImpersonateApplicationMain() {

		// Making NSApplication instance from `NSPrincipalClass` defined in `Info.plist`
		let app = AppMain.applicationClass.shared

		// Configuring application as a regular (appearing in Dock and possibly having UI)
		app.setActivationPolicy(.regular)

		// Loading application menu from `MainMenu.xib` file.
		// This will also assign property `NSApplication.mainMenu`.
		//AppMain.menu.instantiate(withOwner: app, topLevelObjects: nil)

		// Loading initial window controller from `NSMainStoryboardFile` defined in `Info.plist`.
		// Initial window accessible via property NSWindowController.window
		let windowController = AppMain.windowController
		windowController.window?.makeKeyAndOrderFront(nil)

		app.activate(ignoringOtherApps: true)		//TODO: Determine later if this is really necessary or not.
	}

	// Fall into NSApplication's default RUN LOOP, which blocks/doesn't return until a subsequent
	//	app.stop(below) is sent.  Note that this programmatic sequence was painstakingly arrived at
	//	after much more complicated attempts to reproduce the message pump ourselves (via window:
	//	nextEvent, sendEvent, update), which never did perform as expected.
	//	After FallOutOfPreChromiumRunLoop is called, at which time Chromium should be created, we'll
	//	make a non-returning call to change over to its own RunLoop to handle both the macOS/UI and
	//	CEF events.
	//
	static func PumpMessagesPreChromium() {

		let app = AppMain.applicationClass.shared

		app.run()
	}
	static func FallOutOfPreChromiumRunLoop() {

		let app = AppMain.applicationClass.shared

		app.stop(nil)

		KickMessageQueue()
	}

	static func KickMessageQueue() {

		injectKeyPress()
	}

	private static func injectKeyPress() {

		let KeyCode_escape_rawValue: UInt16 = 0x35	//	53

		let eventSource = CGEventSource(stateID: .combinedSessionState)
		if let event = CGEvent(keyboardEventSource: eventSource,
							   virtualKey: KeyCode_escape_rawValue, // "innocuous"?
							   keyDown: true) {
			event.post(tap: .cghidEventTap)
		}
	}
}
