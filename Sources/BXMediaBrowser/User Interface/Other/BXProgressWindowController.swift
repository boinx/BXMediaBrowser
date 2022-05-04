//**********************************************************************************************************************
//
//  BXProgressWindowController.swift
//	A progress bar window that can be presented modally or as a sheet
//  Copyright ©2020-2022 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import BXSwiftUtils
import AppKit
import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


open class BXProgressWindowController : NSWindowController
{
	/// Shared singleton instance of the BXProgressWindowController
	
	public static let shared = BXProgressWindowController(window:nil)

	/// The window for this controller is loaded lazily when accessing this property
	
	override open var window:NSWindow?
	{
		set
		{
			super.window = newValue
		}
		
		get
		{
			if super.window == nil { self.loadWindow() }
			return super.window
		}
	}
	
	/// Returns the observable BXProgressViewController
	
	var viewController:BXProgressViewController?
	{
		self.contentViewController as? BXProgressViewController
	}
	
	/// Loads the window and its view hierarchy
	
	override open func loadWindow()
	{
		let frame = CGRect(x:0, y:0, width:360, height:88)
		let style:NSWindow.StyleMask = [.utilityWindow,.titled,.fullSizeContentView]
		let window = NSWindow(contentRect:frame, styleMask:style, backing:.buffered, defer:true)
		
		window.titleVisibility = .hidden
		window.titlebarAppearsTransparent = true
		window.hasShadow = true
		window.isMovable = true
		window.isMovableByWindowBackground = true
		window.contentViewController = BXProgressViewController(nibName:nil, bundle:nil)

		self.window = window
	}
	
	
	func unloadWindow()
	{
		self.window = nil
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
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
		set { self.viewController?.cancelHandler = newValue }
		get { self.viewController?.cancelHandler }
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	open func show()
	{
		DispatchQueue.main.async
		{
			self.window?.center()
//			self.showWindow(nil)
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

	override open func close()
	{
		super.close()
		self.unloadWindow()
	}

	private func update()
	{
		DispatchQueue.main.asyncIfNeeded
		{
			guard let viewController = self.viewController else { return }
			
			viewController.progressTitle = self.title
			viewController.progressMessage = self.message
			viewController.fraction = self.value
			viewController.isIndeterminate = self.isIndeterminate
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------

#endif
