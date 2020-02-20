//
// main.swift
//	ChromiumTester demo app + Chromium BrowseProcess
//
// Replaces NSApplicationMain and the only place where top-level code can exist.
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2015.07.18
//

import CEFswift
import AppKit


print("main.swift...", terminator: "")	// indicate this top-level code running before anything else

ChromiumModule.Initialize()

let appDelegate = AppDelegate()
appDelegate.createApplication()

AppMain.ImpersonateApplicationMain()

AppMain.PumpMessagesPreChromium()	// Will return, as soon as...

// ...Chromium is created, let it pump its messages as well as the UI's:
ChromiumModule.cefApp?.PumpAllMessages()

// and after the above quits:  (via cef_quit_message_loop)
cef_shutdown()	// *

appDelegate.terminateApplication()

exit(0)


// * - Note that this call results in:
//	WARNING:discardable_shared_memory_manager.cc(436)] Some MojoDiscardableSharedMemoryManagerImpls are still alive. They will be leaked.
//TODO: Fix this eventually. (will require examination of the CEF C++ code)
