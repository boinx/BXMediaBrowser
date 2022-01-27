//**********************************************************************************************************************
//
//  BXProgressWindowController.swift
//	A progress bar window that can be presented modally or as a sheet
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import AppKit


//----------------------------------------------------------------------------------------------------------------------


open class BXProgressWindowController : NSWindowController
{
	public static let shared:BXProgressWindowController =
	{
		let bundle = Bundle.module //(for:BXProgressWindowController.self)
		let storyboard = NSStoryboard(name:"BXProgressViewController", bundle:bundle)
		let controller = storyboard.instantiateInitialController() as! BXProgressWindowController
		
		controller.window?.isMovableByWindowBackground = true
		
		return controller
	}()


	var progressViewController:BXProgressViewController?
	{
		return self.contentViewController as? BXProgressViewController
	}


//----------------------------------------------------------------------------------------------------------------------


	open var title:String = ""
	{
		didSet { self.update() }
	}
	
	open var message:String = ""
	{
		didSet { self.update() }
	}
	
	open var value:Double = 0.0
	{
		didSet { self.update() }
	}
	
	open var isIndeterminate = false
	{
		didSet { self.update() }
	}
	
	open var isVisible:Bool
	{
		self.window?.isVisible ?? false
	}
	
	open var cancelHandler:(()->Void)?
	{
		set { self.progressViewController?.cancelHandler = newValue }
		get { self.progressViewController?.cancelHandler }
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	open func show()
	{
		DispatchQueue.main.asyncIfNeeded
		{
			self.window?.center()
			self.showWindow(nil)
			self.window?.makeKeyAndOrderFront(nil)
		}
	}
	
	
	open func hide()
	{
		DispatchQueue.main.asyncIfNeeded
		{
			self.close()
		}
	}


	func update()
	{
		DispatchQueue.main.asyncIfNeeded
		{
			guard let progressViewController = self.progressViewController else { return }
			
			progressViewController.titleField?.stringValue = self.title
			progressViewController.messageField?.stringValue = self.message
			progressViewController.progressBar?.doubleValue = self.value
			progressViewController.progressBar?.isIndeterminate = self.isIndeterminate
			
			if self.isIndeterminate
			{
				progressViewController.progressBar?.startAnimation(nil)
			}
			else
			{
				progressViewController.progressBar?.stopAnimation(nil)
			}
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif
