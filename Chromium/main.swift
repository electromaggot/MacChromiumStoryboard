//
// main.swift
//	RenderProcess, ChromiumHelper
//
// Beware! Breakpoints set here won't typically be hit, since it's non-main thread.
//
// For the command-line switches used below, note convenient list here: https://peter.sh/experiments/chromium-command-line-switches/
//
// Created by Tadd Jensen on 5/30/19; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//	Originated from CEF.swift © Tamas Lustyik 2017.11.08
//

import Darwin
import CEFswift


print("RenderProcess main.swift TOP-LEVEL CODE running")

let blockingSemaphore = ipcBlockingSemaphore(.GET)		// (create ASAP before any sandboxing*)

var retval: Int = -1
var isRenderProcess = false

CommandLine.arguments.append("--no-sandbox")			// (* - didn't matter, so we must resort to this)
CommandLine.arguments.append("--enable-sandbox-logging")

if let commandLine = CEFCommandLine() {
	commandLine.initFromArguments(CommandLine.arguments)
	isRenderProcess = commandLine.switchValue(for: "type") == "renderer"
}
let mainArgs = CEFMainArgs(arguments: CommandLine.arguments)

if isRenderProcess {
	print("SPAWNED: RENDERER PROCESS    (mainArgs: \(mainArgs))")
	// uncomment the following line in order to have the process paused until a debugger is attached
	//raise(SIGSTOP)
	retval = CEFProcessUtils.executeProcess(with: mainArgs, app: App())
}
else {
	print("SPAWNED: OTHER-THAN-RENDERER PROCESS")
	// other helper processes spawned by CEF
	retval = CEFProcessUtils.executeProcess(with: mainArgs)
}

exit(Int32(retval))
