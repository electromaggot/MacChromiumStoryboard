//
// StartingViewController.swift
//	ChromiumTester ChromiumTester
//
// Created 9/6/19 by Tadd Jensen; follows same BSD-3-Clause-like terms as project
//	on which it is based: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Cocoa

extension NSView {		// recursively enable/disable any child TextFields
	func setEnabled(_ isEnabled: Bool) {
		for subView in self.subviews {
			if let textField = subView as? NSTextField,
			   let textCell = textField.cell {
				textCell.isEnabled = isEnabled
				textField.textColor = isEnabled ? NSColor.controlTextColor : NSColor.disabledControlTextColor
			}
			subView.setEnabled(isEnabled)
		}
	}
}


class StartingViewController: NSViewController {

	static var this: StartingViewController? = nil

	@IBOutlet weak var checkboxLogin: NSButton!
	@IBOutlet weak var boxLogin: NSBox!
	@IBOutlet weak var textUserName: NSTextField!
	@IBOutlet weak var securetextPassword: NSSecureTextField!

	@IBAction func onToggleLogin(_ sender: Any) {
		boxLogin.contentView?.setEnabled(isLogin)
	}

	static var IsLogin: Bool {
		if this == nil { return false }
		return this!.isLogin
	}

	var isLogin: Bool {
		return checkboxLogin.state == .on
	}


    override func viewDidLoad() {
        super.viewDidLoad()

		StartingViewController.this = self

		textUserName.stringValue = NSUserName()

		boxLogin.contentView?.setEnabled(false)
	}

	// If logging in, make sure login is successful before performing segue.
	//
	override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {

		if isLogin {

			return authenticateLoginRequest()
		}
		return true
	}

	private func authenticateLoginRequest() -> Bool {

		let authService = AuthService.sharedInstance

		var didAuthenticate: AuthService.AuthenticationResult = .UNKNOWN

		didAuthenticate = authService.Authenticate(login: textUserName.stringValue,
												password: securetextPassword.stringValue,
													site: "main")
		if didAuthenticate == .PASS {

			ChromiumViewController.IsUserLoggedIn = true
		}
		else if didAuthenticate == .TIMEOUT {

			simplePopUpDialog(title: "Login Failed (Timed-Out)", LOGIN_TIMEOUT_MSG)
		}
		if didAuthenticate == .FAIL {

			simplePopUpDialog(title: "Login Failed", LOGIN_FAIL_MESSAGE)
		}
		return (didAuthenticate == .PASS)
	}
	let LOGIN_FAIL_MESSAGE = "You have entered an incorrect user name or password.  "
						   + "Please correct the information you have provided and attempt your login again."
	let LOGIN_TIMEOUT_MSG  = "There was an error detected with the connection.  "
						   + "Please retry when the connection has been restored."

	private func simplePopUpDialog(title: String, _ subTitle: String) {

		let msgBox = NSAlert()
		msgBox.messageText = title
		msgBox.informativeText = subTitle
		msgBox.alertStyle = NSAlert.Style.warning
		msgBox.runModal()
	}
}
