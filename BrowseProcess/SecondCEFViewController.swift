//
// SecondCEFViewController.swift
//	ChromiumTester ChromiumTester
//
// Created 2/9/20 by Tadd Jensen; follows same BSD-3-Clause-like terms as project
//	on which it depends: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Cocoa
import CEFswift


class SecondCEFViewController: NSViewController {

	static let STORYBOARD_ID = "SecondCEFControllerId"

	@IBOutlet weak var SecondCEFWebView: NSView!
	
	@IBAction func clickedBackButton(_ sender: Any) {
		self.dismiss(self)
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		viewBrowserBar.wantsLayer = true
		viewBrowserBar.layer?.backgroundColor = NSColor.systemBrown.cgColor

		SecondCEFWebView.wantsLayer = true
		SecondCEFWebView.layer?.backgroundColor = NSColor.systemTeal.cgColor
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		if let thisWebView = SecondCEFWebView,
		   let cefApp = ChromiumModule.cefApp {

			ChromiumHandler.instance.OnBrowserCreatedCallback = onBrowserCreated

			cefApp.CreateAdditionalBrowserWith(newChromiumView: thisWebView)

			print("BrowseProcess:  setting CEFWindow as child of ChromiumViewController")
			print("                frame: \(thisWebView.frame) ...  CEFWindowInfo.rect \(CEFWindowInfo().rect)")
		}
	}

	func onBrowserCreated(browser: CEFBrowser) {

		//if let cefApp = ChromiumModule.cefApp {

			if let url = URL(string: ServiceAddresses.WebURLBasePage2) {
				textfieldURL.stringValue = url.absoluteString

				browser.mainFrame?.loadURL(url)
				//cefApp.client.Load(url: url, browser: browser)
			}
		//}
	}


	// BROWSER BAR

	@IBOutlet weak var viewBrowserBar: NSView!
	@IBOutlet weak var textfieldURL: NSTextField!

	@IBAction func enteredURL(_ sender: Any) {
		if let textField = sender as? NSTextField {
			/*if let url = URL(string: BrowserView.ProperURLString(textField.stringValue)) {
				BrowserView.Load(URL: url)
			}*/
			if let url = URL(string: textField.stringValue),
			   let cefApp = ChromiumModule.cefApp {

				cefApp.client.Load(url: url)
			}
		}
	}

	@IBAction func clickedBack(_ sender: Any) {
		if let cefApp = ChromiumModule.cefApp {
			cefApp.client.NavigateBack()
		}
	}
	@IBAction func clickedForward(_ sender: Any) {
		if let cefApp = ChromiumModule.cefApp {
			cefApp.client.NavigateForward()
		}
	}
	@IBAction func clickedReload(_ sender: Any) {
		if let cefApp = ChromiumModule.cefApp {
			cefApp.client.ReloadPage()
		}
	}
	@IBAction func clickedStop(_ sender: Any) {
		if let cefApp = ChromiumModule.cefApp {
			cefApp.client.StopLoading()
		}
	}
}
