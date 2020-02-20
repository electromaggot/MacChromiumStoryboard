//
// SegueOverSlide.swift
//	Common CustomUI Components
//
// Slide "to" viewController onto screen leftwards from off-screen-right,
//	overlapping "from" viewController which remains untouched in background.
//
// "From" controller is retained and chains "to" as a subview, so previous
//	screens can be returned to via "unwind" segue, say from a "back" button.
//
// Created by Tadd Jensen on 9/16/19; follows same BSD-3-Clause-like terms
//	as: https://github.com/lvsti/CEF.swift/blob/master/LICENSE.txt
//

import Cocoa


class SegueOverSlide: NSStoryboardSegue {
	
	override func perform() {
		
		//DO NOT! super.perform()
		
		(sourceController as AnyObject).present(destinationController as! NSViewController,
															  animator: SlideTransitionAnimator())
	}
}


class SlideTransitionAnimator: NSObject, NSViewControllerPresentationAnimator {

	var callbackOnFinish: (() -> Void)?
	
	init(whenFinished: @escaping () -> Void) {
		callbackOnFinish = whenFinished
	}
	
	override init() {
		callbackOnFinish = nil
	}


	let kSecondsAnimationDuration = 0.75

	func animatePresentation(of toViewController: NSViewController, from fromViewController: NSViewController) {
		
		let offScreenRight = NSMakeRect(NSWidth(fromViewController.view.frame),	 // x
										0,										 // y
										NSWidth(fromViewController.view.frame),	 // width
										NSHeight(fromViewController.view.frame)) // height
		
		// Ensure new ViewController can go full-screen:
		toViewController.view.autoresizingMask = [NSView.AutoresizingMask.width,
												  NSView.AutoresizingMask.height]
		var isToAlreadyChildOfFrom: Bool = false
		
		for view in fromViewController.view.subviews {
			if view == toViewController.view {
				isToAlreadyChildOfFrom = true
			}
		}
		if (!isToAlreadyChildOfFrom) {			// Chain-in the new controller...
			fromViewController.view.addSubview(toViewController.view)
		}
		toViewController.view.isHidden = false	// ...and make sure it is visible
		
		toViewController.view.frame = offScreenRight
		let destinationRect: NSRect = fromViewController.view.frame

blog(.STATUS, "### SegueOverSlide.animatePRESENTATION(to \(toViewController), from \(fromViewController)) SLIDE OVER SEGUE BEGIN ###", .DEBUG)
//TODO: This segue needs reanalysis. Its toView was failing to appear until 2nd and subsequent runs.
// However when substituted with SegueImmediate, that worked and appeared 1st time, yet it seems to do
//	everything that this segue generally does, with the exception of setting CurrentViewController earlier.
//	Is that the key? Doesn't make sense though. At very least, should we be doing AddChildViewController
//	or in the Dismissal, RemoveFromParentViewController like SegueImmediate does?  Investigate later.
// That is... if this is even deemed important, since we've deprecated this segue for Disclosures anyway.

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = self.kSecondsAnimationDuration
			context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			
			toViewController.view.animator().frame = destinationRect
			
			}, completionHandler: {

				// DO NOT HIDE previous/parent viewController, or we'll be hidden
				//	too!  Don't move it either.  We should overlay it fully, hence
				//	hide it.
			})
	}
	
	func animateDismissal(of toViewController: NSViewController, from fromViewController: NSViewController) {

		var toVC = toViewController
		if toViewController == fromViewController,
		   let presenter = fromViewController.presentingViewController {
			toVC = presenter
		}

		let offScreenRight = NSMakeRect(NSWidth(fromViewController.view.frame),	 // x
										0,										 // y
										NSWidth(fromViewController.view.frame),	 // width
										NSHeight(fromViewController.view.frame)) // height
		
		let destinationRect: NSRect = offScreenRight
		
blog(.STATUS, "### SegueOverSlide.animateDismissal(to \(toVC), from \(fromViewController)) SLIDE OVER SEGUE END ###", .DEBUG)

		NSAnimationContext.runAnimationGroup({ (context) -> Void in
			context.duration = self.kSecondsAnimationDuration
			context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
			
			fromViewController.view.animator().frame = destinationRect
			
			}, completionHandler: {

blog(.STATUS, "### SegueOverSlide COMPLETION HANDLER (to \(toVC), from \(fromViewController)) ###", .DEBUG)

				// Remove temporary child relationship. (Can reestablish it later.)
				fromViewController.view.removeFromSuperview()

				if self.callbackOnFinish != nil {
					self.callbackOnFinish!()
				}
			})
	}
}
