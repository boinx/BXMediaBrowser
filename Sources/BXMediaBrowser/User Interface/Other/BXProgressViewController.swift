//**********************************************************************************************************************
//
//  BXProgressViewController.swift
//	A progress bar window that can be presented modally or as a sheet
//  Copyright ©2020 Peter Baumgartner. All rights reserved.
//
//**********************************************************************************************************************


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


#if os(macOS)

import AppKit

open class BXProgressViewController : NSViewController, ObservableObject
{
	@Published open var progressTitle:String? = nil
	@Published open var isIndeterminate:Bool = false
	@Published open var fraction:Double = 0.0
	@Published open var progressMessage:String? = nil
	open var cancelHandler:(()->Void)? = nil

	override open func loadView()
	{
		let frame = CGRect(x:0, y:0, width:360, height:104)
		
		let hostView = NSHostingView(rootView: BXProgressView(controller:self))
		hostView.frame = frame
		hostView.autoresizingMask = [.width,.height]
		
		self.view = BXProgressBackgroundView(frame:frame)
		self.view.addSubview(hostView)
	}
}

public class BXProgressBackgroundView : NSView
{
	override public var mouseDownCanMoveWindow: Bool
	{
		true
	}
	
	override public var canBecomeKeyView: Bool
	{
		true
	}
}


#endif

	
//----------------------------------------------------------------------------------------------------------------------


#if os(iOS)

import UIKit

open class BXProgressViewController : UIHostingController<BXProgressView>, ObservableObject
{
	@Published open var progressTitle:String? = nil
	@Published open var isIndeterminate:Bool = false
	@Published open var fraction:Double = 0.0
	@Published open var progressMessage:String? = nil
	open var cancelHandler:(()->Void)? = nil

	override open func loadView()
	{
		self.rootView = BXProgressView(controller:self)
	}
}


#endif

	
//----------------------------------------------------------------------------------------------------------------------
