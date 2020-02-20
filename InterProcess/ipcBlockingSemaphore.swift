//
// ipcBlockingSemaphore.swift
//	Chromium, shared between Render and Browser Processes
//
// Created 11/18/19 by Tadd Jensen; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Foundation


class ipcBlockingSemaphore {

	let NAME = "/ipcSyncSemaphore"

	var semaphore: UnsafeMutablePointer<sem_t>? = nil

	enum Mode {
		case CREATE
		case GET
	}

	// Construct early!  Before sandboxing makes the sem_opens fail...
	// http://dev.chromium.org/developers/design-documents/sandbox/osx-sandboxing-design
	//
	init(_ mode: Mode) {

		if mode == .CREATE {
			var retries = 5
			while semaphore == nil && retries > 0 {
				semaphore = sem_open(NAME, O_CREAT | O_EXCL, 0o0644, 0)
				if semaphore == SEM_FAILED {
					sem_unlink(NAME)
					blog(" // //  SEMAPHORE \"\(NAME)\" EXISTED/UNLINKED FIRST")
					semaphore = nil
				}
				retries -= 1
			}
		}
		else {
			//semaphore = sem_open(NAME, O_RDONLY)
			semaphore = sem_open(NAME, O_CREAT)
		}
		let didFail = semaphore == SEM_FAILED

		blog( "// // / SEMAPHORE \"\(NAME)\" \(didFail ? "FAILURE TO" : "SUCCESSFUL") \(mode)    \(String(describing: semaphore))")
		if didFail {
			perror("/ // // sem_open")
			//exit(EXIT_FAILURE)
		}

		//defer { sem_close(semaphore); sem_unlink(NAME) }
	}

	deinit {

		sem_close(semaphore)
		sem_unlink(NAME)
	}


	func Wait() {

		blog("########  W A I T I N G  ! ! !  ########  \(String(describing: semaphore))")

		let result = sem_wait(semaphore)

		if result != 0 {
			perror("/ // // sem_wait")
		}
		blog("########  Wait.... N O   L O N G E R   W A I T I N G.")
	}

	func Post() {

		blog("########  P O S T I N G  ! ! !  ########")	//TODO: Delete these ugly prints eventually,
															//	especially if they're polluting our logs.
		sem_post(semaphore)
	}
}
