//**********************************************************************************************************************
//
//  BXProgressWindowController.swift
//	A progress bar window that can be presented modally or as a sheet
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


#if os(macOS)

import BXSwiftUtils
import AppKit


//----------------------------------------------------------------------------------------------------------------------


open class BXProgressWindowController : NSWindowController
{
	public static let shared:BXProgressWindowController =
	{
		let style:NSWindow.StyleMask = [.utilityWindow,.unifiedTitleAndToolbar]
		
		let window = NSWindow(
			contentRect: CGRect(x:0, y:0, width:360, height:104),
			styleMask: style,
			backing: .buffered,
			defer: true)
		
		window.styleMask = style
		window.isMovableByWindowBackground = true
		window.titlebarAppearsTransparent = true
		window.titleVisibility = .hidden
		window.hasShadow = true
		
		return BXProgressWindowController(window:window)
	}()

	override public init(window:NSWindow?)
	{
		let viewController = BXProgressViewController(nibName:nil, bundle:nil)
		self.viewController = viewController
		window?.contentView = viewController.view
		
		super.init(window:window)
	}
	
	public required init?(coder:NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
	
	private var viewController:BXProgressViewController? = nil


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
		set { self.viewController?.cancelHandler = newValue }
		get { self.viewController?.cancelHandler }
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
